# RFP Approver — Teams Bot Integration Reference

**Version:** 2.0.0  
**Date:** 2026-07-04  
**Replaces:** Channel-tab design (v1.0.0, SWA-based)

---

## 1. Architecture Overview

```
Teams Client
    │  user attaches 2 PDFs + sends message
    ▼
Azure Bot Service (bot-oh-rfp-approver)
    │  forwards signed Activity to messaging endpoint
    ▼
Azure Functions — /api/messages  (func-oh-rfp-approver)
    │  BotFrameworkAdapter verifies JWT, dispatches to RfpApproverBot
    ▼
RfpApproverBot (api/teams_bot.py)
    │  downloads PDFs from Teams file download URLs via aiohttp
    │  extracts text with pypdf
    ▼
FoundryAgentClient (api/agent_client.py)
    │  calls Azure AI Foundry agent (oh-rfpApprover1)
    │  optionally grounds via Azure AI Search (rfp-index)
    ▼
Inline Markdown response back to Teams chat thread
```

The Static Web App and channel-tab configuration are removed entirely.  
The single Azure Functions app now serves both the REST API and the bot messaging endpoint.

---

## 2. Azure Bot Service Integration

### 2.1 What Azure Bot Service Does

Azure Bot Service is the Azure-managed relay that connects Microsoft Teams (and other Bot Framework channels) to your bot logic.  
It handles:
- Channel-level routing (Teams → your endpoint)
- Activity signing (HMAC + JWT)
- Channel configuration (Teams channel features, file upload consent)

**Reference:** [Azure Bot Service overview](https://learn.microsoft.com/en-us/azure/bot-service/bot-service-overview)

### 2.2 Resource Provisioned

```bicep
resource botService 'Microsoft.BotService/botServices@2022-09-15' = {
  name: 'bot-oh-rfp-approver'
  location: 'global'          // Bot Services are always global
  kind: 'azurebot'
  sku: { name: 'S1' }
  properties: {
    msaAppId: botMicrosoftAppId          // Entra App Registration client ID
    msaAppType: 'SingleTenant'
    msaAppTenantId: subscription().tenantId
    endpoint: 'https://func-oh-rfp-approver.azurewebsites.net/api/messages'
  }
}
```

`location: 'global'` is required — Bot Service resources do not support regional placement.  
**Reference:** [Bot Service resource provider](https://learn.microsoft.com/en-us/azure/bot-service/bot-service-resources-bot-framework-faq)

### 2.3 Entra App Registration (Required Pre-Step)

The Bot Service requires an Entra ID App Registration so it can sign activities with a verifiable identity.

```bash
# 1. Create the app registration
az ad app create --display-name "RFP Approver Bot" --sign-in-audience AzureADMyOrg

# 2. Note the appId (client ID) — use it for botMicrosoftAppId in main.bicepparam
az ad app list --display-name "RFP Approver Bot" --query "[0].appId" -o tsv

# 3. Create a client secret
az ad app credential reset --id <appId> --display-name "bot-secret"
# Store the returned password in the Function App setting MICROSOFT_APP_PASSWORD
```

**Reference:** [Register a bot with Azure Bot Service](https://learn.microsoft.com/en-us/azure/bot-service/bot-service-quickstart-registration)

### 2.4 BotFrameworkAdapter Authentication

`api/bot_adapter.py` creates a `BotFrameworkAdapter` using the App Registration credentials:

```python
settings = BotFrameworkAdapterSettings(
    app_id=os.environ["MICROSOFT_APP_ID"],
    app_password=os.environ["MICROSOFT_APP_PASSWORD"],
)
adapter = BotFrameworkAdapter(settings)
```

On every incoming POST to `/api/messages`, the adapter:
1. Reads the `Authorization: Bearer <jwt>` header sent by Azure Bot Service.
2. Validates the JWT signature against Microsoft's OpenID metadata endpoint.
3. Verifies the audience (`botId`) and issuer match the registered app.
4. Only dispatches to the bot handler if validation passes.

The `/api/messages` Function route is anonymous at the Azure Functions level — authentication is handled entirely by the Bot Framework layer, which is the standard and recommended approach.

**Reference:** [Bot Framework authentication](https://learn.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-connector-authentication)

### 2.5 Teams Channel Resource

```bicep
resource botTeamsChannel 'Microsoft.BotService/botServices/channels@2022-09-15' = {
  parent: botService
  name: 'MsTeamsChannel'
  properties: {
    channelName: 'MsTeamsChannel'
    properties: { isEnabled: true }
  }
}
```

Enabling the Teams channel registers the bot for Teams-specific features, including file upload activities and Teams-scoped token validation.

**Reference:** [Connect a bot to Teams](https://learn.microsoft.com/en-us/azure/bot-service/bot-service-channel-connect-teams)

---

## 3. Teams App Manifest Changes

### 3.1 What Changed (v1.0.0 → v2.0.0)

| Field | v1.0.0 (tab) | v2.0.0 (bot) |
|-------|-------------|-------------|
| `version` | `1.0.0` | `2.0.0` |
| `configurableTabs` | Present (channel tab) | **Removed** |
| `bots` | Absent | **Added** |
| `supportsFiles` | N/A | `true` |
| `scopes` | `["team"]` | `["personal","team","groupchat"]` |
| `defaultInstallScope` | `team` | `personal` |
| `validDomains` | `swa-oh-rfp-approver.azurestaticapps.net` | `func-oh-rfp-approver.azurewebsites.net` |

### 3.2 The `bots` Block

```json
"bots": [
  {
    "botId": "<MICROSOFT_APP_ID>",
    "scopes": ["personal", "team", "groupchat"],
    "supportsFiles": true,
    "isNotificationOnly": false
  }
]
```

- **`botId`** must exactly match the Entra App Registration client ID set in `botMicrosoftAppId`. Teams uses this to route activities to the correct Bot Service resource.
- **`supportsFiles: true`** is required to allow users to attach files in the bot conversation. Without this, the Teams client will not show the file attachment button.
- **`scopes`** controls where the bot can be installed: personal 1:1 chat, team channels, or group chats.

**Reference:** [Teams app manifest schema — bots](https://learn.microsoft.com/en-us/microsoftteams/platform/resources/schema/manifest-schema#bots)

### 3.3 Packaging and Deployment

```powershell
# Build the sideload ZIP
Compress-Archive -Path teams-app/manifest.json, teams-app/icons `
  -DestinationPath teams-app/ohsupparfp-teams-app-v2.zip -Force
```

**Sideload (dev/test):**  
Teams → Apps → Manage your apps → Upload a custom app → Upload a custom app → select the ZIP.

**Org-wide publish (production):**  
Upload the ZIP to the **Teams Admin Center** → Teams apps → Manage apps → Upload.  
Users can then install from the org app catalog without developer permissions.

**Reference:** [Publish a custom app to your org's app store](https://learn.microsoft.com/en-us/microsoftteams/upload-custom-apps)

---

## 4. File Upload Process in Teams Bot

### 4.1 How Teams Delivers Uploaded Files

When a user attaches a file to a Teams bot chat message:
1. Teams uploads the file to the user's **OneDrive for Business** storage.
2. Teams delivers the bot activity with an attachment of `contentType: "application/vnd.microsoft.teams.file.download.info"`.
3. The attachment `content` object contains a `downloadUrl` — a pre-authenticated, time-limited URL to the file content.

The bot does **not** need to handle a file consent card flow for reading files (consent cards are only required when the *bot* wants to proactively send a file to a user). For user-uploaded files, the download URL is provided directly.

**Reference:** [Send and receive files with bots in Teams](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/how-to/bots-filesv2)

### 4.2 How the Bot Identifies File Attachments

```python
file_attachments = [
    a
    for a in turn_context.activity.attachments
    if a.content_type == "application/vnd.microsoft.teams.file.download.info"
]
```

Non-file messages (plain text) are filtered out here and receive usage instructions.  
The bot expects exactly 2 file attachments in a single message: the first is treated as the RFP, the second as the vendor response.

### 4.3 Downloading Files

```python
async with aiohttp.ClientSession() as session:
    rfp_bytes = await _download_file(session, rfp_att.content["downloadUrl"])
    response_bytes = await _download_file(session, resp_att.content["downloadUrl"])
```

The `downloadUrl` is a pre-authenticated HTTPS URL served by Microsoft Graph/SharePoint.  
No additional authorization headers are required — the URL itself carries the auth token.

**Reference:** [File attachment object schema](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/how-to/bots-filesv2#file-download-info-attachment)

### 4.4 Text Extraction

The bot uses the same `pypdf.PdfReader` logic as the existing `/api/recommend` Function endpoint.  
Text-based PDFs are supported. Scanned (image-only) PDFs are rejected with a user-facing error message — OCR is out of scope.

```python
recommendation = await asyncio.get_event_loop().run_in_executor(
    None,
    _agent_client.generate_recommendation,
    rfp_text,
    response_text,
)
```

`generate_recommendation` uses the synchronous `azure-ai-projects` SDK. It is dispatched to a thread pool executor so it does not block the asyncio event loop while the Bot Framework adapter awaits the response.

**Reference:** [azure-ai-projects Python SDK](https://learn.microsoft.com/en-us/python/api/overview/azure/ai-projects-readme)

---

## 5. Local Development

```bash
# Start the Functions host (serves both /api/recommend and /api/messages)
cd api
func start

# In Bot Framework Emulator, connect to:
#   http://localhost:7071/api/messages
#   App ID: (leave blank)
#   App Password: (leave blank)
```

When `MICROSOFT_APP_ID` and `MICROSOFT_APP_PASSWORD` are empty, `BotFrameworkAdapter` runs in unauthenticated development mode and skips JWT verification.  
**Never deploy with empty credentials.**

**Reference:** [Bot Framework Emulator](https://learn.microsoft.com/en-us/azure/bot-service/bot-service-debug-emulator)

---

## 6. Deployment Checklist

1. **Create Entra App Registration** and note the `appId`.
2. **Create a client secret** for the app registration; save it securely.
3. **Fill in `main.bicepparam`**: set `botMicrosoftAppId` to the `appId`.
4. **Deploy Bicep**: `az deployment group create --resource-group <rg> --template-file infra/main.bicep --parameters infra/main.bicepparam`
5. **Set `MICROSOFT_APP_PASSWORD`** in the Function App application settings (portal or `az functionapp config appsettings set`).
6. **Replace `<MICROSOFT_APP_ID>`** in `teams-app/manifest.json` with the actual `appId`.
7. **Package and deploy the manifest**: build the ZIP and upload to Teams Admin Center.
8. **Test end-to-end**: install the bot, send a message with 2 PDFs, verify inline response.
