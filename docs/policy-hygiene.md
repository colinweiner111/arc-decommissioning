# Policy hygiene

> Need help discovering machines or scopes? See [`docs/inventory.md`](inventory.md) for Azure Resource Graph queries.

This guide shows how to **list and optionally delete Arc-related Azure Policy assignments** using the provided scripts.
Keep this focused on policy cleanup so decommissioning Arc doesn't leave compliance noise.

## Prerequisites
- Azure CLI (`az`) installed (Cloud Shell has it)
- Permissions to **read** and (if deleting) **delete** policy assignments at the chosen scope
- Optional: `jq` if you're using the Bash script locally

## Parameters (both scripts)
- **Scope** — where to search:
  - Subscription: `/subscriptions/<SUB_ID>`
  - Resource group: `/subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>`
  - Management group: `/providers/Microsoft.Management/managementGroups/<MG_ID>`
- **Regex** — case-insensitive pattern to match Arc/agent policy assignment names (see examples)
- **Delete flag** — PowerShell: `-Delete` (with optional `-WhatIf`); Bash: third positional argument `true`

## Safe workflow
1. Run a **dry-run** to list matches (no deletion).
2. Tighten or adjust the regex if any critical assignment appears.
3. Run with delete (use `-WhatIf` first in PowerShell).

## PowerShell examples
```powershell
# Dry-run at subscription scope
$Scope = "/subscriptions/00000000-0000-0000-0000-000000000000"
.\scripts\policy-hygiene.ps1 `
  -Scope $Scope

# Use a custom regex (case-insensitive)
$Regex = '(?i)(Arc|ArcBox|AzureMonitor(Windows|Linux)Agent|AMA|MDE\.(Windows|Linux)|Change\s*Tracking(-Linux)?)'
.\scripts\policy-hygiene.ps1 `
  -Scope $Scope `
  -Regex $Regex

# Delete (preview first)
.\scripts\policy-hygiene.ps1 `
  -Scope $Scope `
  -Delete -WhatIf

# Delete for real
.\scripts\policy-hygiene.ps1 `
  -Scope $Scope `
  -Delete
```

### Management group scope (PowerShell)
```powershell
$MG = "/providers/Microsoft.Management/managementGroups/<MG_ID>"
.\scripts\policy-hygiene.ps1 `
  -Scope $MG                # dry-run
.\scripts\policy-hygiene.ps1 `
  -Scope $MG `
  -Delete -WhatIf           # preview deletes
```

## Bash / Cloud Shell examples
```bash
# Dry-run at subscription scope
SUB="/subscriptions/00000000-0000-0000-0000-000000000000"
REGEX='(?i)(Arc|ArcBox|AzureMonitor(Windows|Linux)Agent|AMA|MDE\.(Windows|Linux)|Change\s*Tracking(-Linux)?)'
./scripts/policy-hygiene.sh "$SUB" "$REGEX"

# Delete at subscription scope
./scripts/policy-hygiene.sh "$SUB" "$REGEX" true
```

### Management group scope (Bash)
```bash
MG="/providers/Microsoft.Management/managementGroups/<MG_ID>"
./scripts/policy-hygiene.sh "$MG" "$REGEX"
./scripts/policy-hygiene.sh "$MG" "$REGEX" true
```

## Advanced matching (optional regex sets)
You can expand the regex to catch legacy/adjacent items:
- **Legacy MMA/OMS:** `MicrosoftMonitoringAgent|OmsAgentForLinux|Log\s*Analytics\s*agent`
- **VM insights:** `VM\s*insights|Deploy\s*VM\s*Insights|DependencyAgent(Windows|Linux)`
- **Guest config/updates:** `Guest\s*Configuration|Update\s*Manager|Update\s*Management|Patch(ing|Assessment)`

Example combined pattern:
```powershell
$Regex = '(?i)(\bArc\b|ArcBox|AzureMonitor(Windows|Linux)Agent|AMA\b|MDE\.(Windows|Linux)|Change\s*Tracking(-Linux)?|MicrosoftMonitoringAgent|OmsAgentForLinux|Log\s*Analytics\s*agent|VM\s*insights|Deploy\s*VM\s*Insights|DependencyAgent(Windows|Linux)|Guest\s*Configuration|Update\s*Manager|Update\s*Management|Patch(ing|Assessment))'
```

## Notes
- Start with dry-run. If in doubt, add `-WhatIf` (PowerShell) or omit the third arg (Bash).
- Prefer specific names (e.g., `AzureMonitorWindowsAgent`) over broad words.
- Keep an internal allow-list for critical assignments you never want to delete.
```
