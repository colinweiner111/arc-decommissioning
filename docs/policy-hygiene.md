# Policy hygiene

> Need help discovering machines or scopes? See [`docs/inventory.md`](inventory.md) for Azure Resource Graph queries.

Use these scripts to **list** and (optionally) **delete** Arc-related Azure Policy assignments so decommissioning Arc doesn't leave compliance noise.

## Prerequisites
- Azure CLI (`az`) available (Cloud Shell is fine)
- Permissions to **read** and (if deleting) **delete** policy assignments at the scope you choose

## Recommended workflow
1. Run a **dry-run** to list matches (no deletion).
2. If the list looks right, run the deletion form.

## PowerShell
```powershell
# Subscription scope
$SUB = "/subscriptions/00000000-0000-0000-0000-000000000000"
.\scripts\policy-hygiene.ps1 `
  -Scope $SUB                         # dry-run
.\scripts\policy-hygiene.ps1 `
  -Scope $SUB -Delete                 # delete

# Management Group scope
$MG = "/providers/Microsoft.Management/managementGroups/<MG_ID>"
.\scripts\policy-hygiene.ps1 `
  -Scope $MG                          # dry-run
.\scripts\policy-hygiene.ps1 `
  -Scope $MG -Delete                  # delete
```

## Bash / Cloud Shell
```bash
# Subscription scope
SUB="/subscriptions/00000000-0000-0000-0000-000000000000"
./scripts/policy-hygiene.sh "$SUB"          # dry-run
./scripts/policy-hygiene.sh "$SUB" true     # delete

# Management Group scope
MG="/providers/Microsoft.Management/managementGroups/<MG_ID>"
./scripts/policy-hygiene.sh "$MG"           # dry-run
./scripts/policy-hygiene.sh "$MG" true      # delete
```

> Advanced matching via custom regex is supported by both scripts, but intentionally omitted here for simplicity.
> If you need it later, we can add a short appendix with a couple of safe patterns.
