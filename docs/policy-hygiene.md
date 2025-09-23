# Policy Hygiene — Azure Arc Decommissioning

Use these scripts to **list** Arc-related Azure Policy assignments and **optionally delete** them to reduce compliance noise after Arc decommissioning.

> ⚠️ **Caution**: Deleting a policy assignment affects posture evaluations at its scope. Use narrow scopes and review with your governance team.

## What counts as “Arc-related”?
By default we match display names that include:
- `Arc`, `ArcBox`
- `Change Tracking`
- `AzureMonitorWindowsAgent` or `AMA`
- `MDE.Windows`

This is a **heuristic**. Adjust the regex to fit your org’s naming conventions.

## PowerShell
**Dry-run (list only):**
```powershell
.\scripts\policy-hygiene.ps1 -Scope /subscriptions/<subId>
```

**Delete matches (with Safety):**
```powershell
# Preview what would be deleted:
.\scripts\policy-hygiene.ps1 -Scope /subscriptions/<subId> -Delete -WhatIf

# Actually delete (remove -WhatIf):
.\scripts\policy-hygiene.ps1 -Scope /subscriptions/<subId> -Delete
```

### Parameters
- `-Scope` — MG/subscription/RG scope (e.g., `/providers/Microsoft.Management/managementGroups/<mg>`, `/subscriptions/<subId>`)
- `-Regex` — override default matching pattern
- `-Delete` — perform deletion (respects `-WhatIf`)

## Bash / Linux
**Dry-run (list only):**
```bash
./scripts/policy-hygiene.sh "/subscriptions/<subId>" '(?i)(\bArc\b|ArcBox|Change\s*Tracking|AzureMonitorWindowsAgent|AMA\b|MDE\.Windows)'
```

**Delete matches:**
```bash
./scripts/policy-hygiene.sh "/subscriptions/<subId>" '(?i)(\bArc\b|ArcBox|Change\s*Tracking|AzureMonitorWindowsAgent|AMA\b|MDE\.Windows)' true
```

### Arguments
1. `SCOPE` — MG/subscription/RG scope
2. `REGEX` — regex for displayName match (quoted)
3. `DELETE` — use `true` to delete; omit for dry-run

## Good practice
- Prefer **removing or narrowing** Arc-only policy assignments **before** disconnecting Arc.
- If policies are still needed for a subset, **scope to resource type** `Microsoft.HybridCompute/machines` or use policy conditions to avoid non-Arc resources.
- Track changes via PRs and note removals in `CHANGELOG.md`.
