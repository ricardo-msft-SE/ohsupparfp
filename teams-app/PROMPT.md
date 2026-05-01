# GitHub Copilot Prompt: Expose Foundry Agent to Microsoft Teams

Share this prompt with your team members who need to create a Teams channel tab for their own Foundry web UI.

---

## Prompt

**I want to expose my Foundry agent to Microsoft Teams as a channel tab. The tab should link directly to my existing web UI—no file upload integration.**

**Please provide:**
1. A Teams app manifest configured for channel-scoped tab installation.
2. A tab configuration page that users see when adding the tab to a channel.
3. Placeholder icons (32×32 color and 192×192 outline).
4. Instructions for packaging and sideloading into Teams.
5. Guidance on updating the URL if my web UI endpoint changes.

**My web UI is hosted at:**
```
[REPLACE WITH YOUR CONTAINER APP FQDN OR HOSTING URL]
```

**App name:** RFP Approver *(or customize as needed)*

**Installation scope:** Team channels only *(personal app not required)*

---

## What You'll Get

- A `teams-app/` folder with `manifest.json`, tab config page, and icons.
- A ready-to-sideload ZIP package.
- Clear instructions for sideloading into Teams and updating URLs later.
- No backend code changes required—your existing web UI is linked directly.

---

## How Copilot Will Help

Copilot will:
1. Ask for your web UI URL and app metadata.
2. Generate a Teams manifest with channel-tab configuration.
3. Create a lightweight HTML config page using Teams JS SDK.
4. Generate placeholder PNG icons for Teams app store.
5. Package everything into a sideloadable ZIP.
6. Provide a README with sideload steps and update guidance.

---

## Next Steps (After Copilot Generates Files)

1. Open Microsoft Teams.
2. Go to **Apps** → **Manage your apps** → **Upload an app**.
3. Choose **Upload a custom app** and select the ZIP.
4. Add the app to a team and channel.
5. Click **Save** in the configuration dialog.

Done—your Foundry agent is now in Teams!
