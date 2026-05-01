# Teams App Package (Channel Tab)

This package exposes the deployed Foundry web UI in Microsoft Teams as a channel tab.

## Current Target URL

https://oh-rfp-approver-web.agreeablefield-acc5866b.eastus2.azurecontainerapps.io/

## Files

- `manifest.json`: Teams app manifest (channel-tab only).
- `icons/color.png`: Placeholder color icon (32x32).
- `icons/outline.png`: Placeholder outline icon (192x192).

## How to Build the Sideload Zip

From the repository root in PowerShell:

```powershell
Compress-Archive -Path teams-app/manifest.json,teams-app/icons -DestinationPath teams-app/ohsupparfp-teams-app.zip -Force
```

## Sideload in Teams

1. Open Microsoft Teams.
2. Go to **Apps** > **Manage your apps** > **Upload an app**.
3. Choose **Upload a custom app** and select `teams-app/ohsupparfp-teams-app.zip`.
4. Add the app to a team and channel.
5. In the configuration screen, click **Save**.

## Update URL Later

When your host URL changes, update both:

- `teams-app/manifest.json` (`configurationUrl`, `validDomains`, and all developer URLs)
- `src/static/teams/config.html` (`APP_URL`)

Then rebuild and sideload a new zip after increasing `manifest.json` version.
