# Azure AI Search + Blob Guided Setup

This repository now includes a menu-driven setup script to provision and configure Azure AI Search and Blob Storage for PDF document indexing, with RBAC-focused configuration and explicit step gating.

## Files

- scripts/setup-search-storage.ps1
- infra/search-storage.bicep

## Run

```powershell
pwsh -File .\scripts\setup-search-storage.ps1
```

To reset saved progress:

```powershell
pwsh -File .\scripts\setup-search-storage.ps1 -ResetState
```

The script stores progress in:

- .azure/search-setup-state.json

## Numbered Workflow

1. Prerequisite checks
2. Select tenant/subscription and resource names
3. Collect Foundry and app identity info (supports auto-discovery)
4. Deploy Search + Blob infrastructure (Bicep)
5. Apply RBAC assignments
6. RBAC propagation wait and re-check
7. Create data source and index
8. Create and run indexer
9. Upload sample PDF
10. Query smoke test
11. Show app environment values

## Inputs You May Need

- Azure tenant and subscription access
- Resource naming/location preferences
- App managed identity principal/object ID (optional but recommended)
- Foundry resource group/name (optional, only needed when applying Azure AI User role)
- Path to a local PDF for upload testing

## Notes

- The setup flow uses Azure RBAC and managed identity patterns.
- Steps are independent and resumable through the saved state file.
- If role assignments are not visible immediately, rerun step 6 until propagation completes.
- Step 3 can automatically discover likely Foundry resources in the active subscription and let you select one from a numbered list.
- After each successful step, the script prints a recommended next step hint.
