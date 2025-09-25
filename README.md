
# Azure Arc Decommissioning

This repo contains a practical runbook and helper scripts for safely decommissioning **Azure Arc** at scale (≈30+ servers).
> **Shells:** This repo uses the **Azure CLI (`az`)**, which runs the same in **PowerShell** and **Bash** (including Azure Cloud Shell). Commands below apply to both unless noted.


> Start here: **arc-decommissioning-runbook.md** (put the file at the repo root).

## What this covers
- Pre-work: inventory, Defender scope, AMA autoprovisioning
- Sequenced steps: policy hygiene → remove extensions → disconnect Arc → post-cleanup
- Handy `az`/PowerShell/**Bash** examples
- Tips to avoid compliance noise and stale Defender/MDE entries

## Quickstart
1. **Read the runbook**: `./arc-decommissioning-runbook.md`  
2. **Use scripts** in `./scripts` to list/remove extensions and disconnect machines (PowerShell **or** Bash).  
3. **Validate**: Defender for Cloud inventory/MDE devices are clean; Policy compliance converges.


## Prerequisites

These steps apply to **both PowerShell and Bash** (Azure CLI):

Install/upgrade the **Resource Graph** Azure CLI extension (required for inventory queries):

```bash
az extension add --name resource-graph --upgrade
```

(Optional) Set your subscription context:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
```

### Cloud Shell quick tips
- Cloud Shell defaults to **Bash**; use the `*.sh` scripts and save outputs under `~/clouddrive/`:
  ```bash
  chmod +x scripts/*.sh
  ./scripts/list-arc-machines.sh "<SUBSCRIPTION_ID>" ~/clouddrive/arc-machines.csv
  ```
- To use **PowerShell** in Cloud Shell, switch to it (`pwsh`) and run the `*.ps1` scripts:
  ```powershell
  .\scripts\list-arc-machines.ps1 -CsvPath ~/clouddrive/arc-machines.csv
  ```


## Safety checklist (TL;DR)
- ✅ Defender plan enabled at the correct scope (subscription; RG only if needed)
- ✅ AMA/MDE onboarding healthy for destination Azure VMs
- ✅ Arc-only policy assignments removed or scoped to `Microsoft.HybridCompute/machines`
- ✅ Arc extensions (**MDE.Windows**, **AzureMonitorWindowsAgent (AMA)**, **ChangeTracking**) uninstalled **before** disconnect
- ✅ `azcmagent disconnect` run on each server (or `az connectedmachine delete` if unreachable)
- ✅ Post-cleanup: no stale Defender/MDE entries; Policy compliance noise resolved

## Scripts

### Inventory & lifecycle
**PowerShell**
- `scripts/list-arc-machines.ps1` — list Arc machines (optionally export CSV)
- `scripts/list-arc-extensions.ps1` — list extensions on a specific machine
- `scripts/remove-arc-extension.ps1` — remove a specific extension or a common set
- `scripts/disconnect-arc.ps1` — Azure-side delete fallback (when you can’t reach the server)

**Bash / Linux**
- `scripts/list-arc-machines.sh` — list Arc machines (optionally export CSV)
- `scripts/list-arc-extensions.sh` — list extensions on a specific machine
- `scripts/remove-arc-extension.sh` — remove a specific extension or a common set
- `scripts/disconnect-arc.sh` — Azure-side delete fallback (when you can’t reach the server)

### Policy hygiene
- **PowerShell:** `scripts/policy-hygiene.ps1` — list & optionally delete Arc-related policy assignments (supports `-Delete` and `-WhatIf`)
- **Bash:** `scripts/policy-hygiene.sh` — list & optionally delete Arc-related policy assignments (third arg `true` performs deletion)

See **[docs/policy-hygiene.md](./docs/policy-hygiene.md)** for details, regex customization, and safety tips.

## Usage examples

💡 **Placeholders**:
- `<MACHINE_NAME>` = the Arc-connected server's name (Azure resource name)
- `<RESOURCE_GROUP>` = the Azure resource group that contains the Arc machine resource

### PowerShell
```powershell
# List Arc machines (and save CSV)
.\scripts\list-arc-machines.ps1 -CsvPath .\rc-machines.csv

# List extensions on a machine
.\scripts\list-arc-extensions.ps1 -MachineName <MACHINE_NAME> -ResourceGroup <RESOURCE_GROUP>

# Remove common Arc extensions
.\scripts
emove-arc-extension.ps1 -MachineName <MACHINE_NAME> -ResourceGroup <RESOURCE_GROUP> -CommonSet

# Disconnect (Azure-side) if host unreachable
.\scripts\disconnect-arc.ps1 -MachineName <MACHINE_NAME> -ResourceGroup <RESOURCE_GROUP>

# Policy hygiene (dry-run)
.\scripts\policy-hygiene.ps1 -Scope /subscriptions/00000000-0000-0000-0000-000000000000

# Policy hygiene (delete with WhatIf confirmation)
.\scripts\policy-hygiene.ps1 -Scope /subscriptions/00000000-0000-0000-0000-000000000000 -Delete -WhatIf
```

### Bash / Linux
```bash
# Make scripts executable (first time)
chmod +x scripts/*.sh

# List Arc machines (and save CSV)
./scripts/list-arc-machines.sh "<SUBSCRIPTION_ID>" ./arc-machines.csv

# List extensions on a machine
./scripts/list-arc-extensions.sh <MACHINE_NAME> <RESOURCE_GROUP>

# Remove common Arc extensions
./scripts/remove-arc-extension.sh -m <MACHINE_NAME> -g <RESOURCE_GROUP> --common-set

# Disconnect (Azure-side) if host unreachable
./scripts/disconnect-arc.sh -m <MACHINE_NAME> -g <RESOURCE_GROUP>


# Policy hygiene (dry-run)
SUB="/subscriptions/00000000-0000-0000-0000-000000000000"
./scripts/policy-hygiene.sh "$SUB"

# Policy hygiene (perform deletion)
./scripts/policy-hygiene.sh "$SUB" true```

## Azure Cloud Shell tips

If you're running these commands in **Azure Cloud Shell**:

- **Install/upgrade Resource Graph extension** (required for inventory queries):
  ```bash
  az extension add --name resource-graph --upgrade
  ```

- **Bash examples** (Cloud Shell defaults to Bash):
  ```bash
  # Persist output in your Cloud Shell drive
  chmod +x scripts/*.sh
  ./scripts/list-arc-machines.sh "<SUBSCRIPTION_ID>" ~/clouddrive/arc-machines.csv
  ./scripts/list-arc-extensions.sh <MACHINE_NAME> <RESOURCE_GROUP>
  ./scripts/remove-arc-extension.sh -m <MACHINE_NAME> -g <RESOURCE_GROUP> --common-set
  ./scripts/disconnect-arc.sh -m <MACHINE_NAME> -g <RESOURCE_GROUP>
  ```

- **PowerShell shell in Cloud Shell**: switch to PowerShell (via UI or `pwsh`) and use the `*.ps1` scripts:
  ```powershell
  az extension add --name resource-graph --upgrade
  .\scripts\list-arc-machines.ps1 -CsvPath ~/clouddrive/arc-machines.csv
  .\scripts\list-arc-extensions.ps1 -MachineName <MACHINE_NAME> -ResourceGroup <RESOURCE_GROUP>
  ```

## Requirements
- **Azure CLI** (with extension: `resource-graph`; Linux requires `jq` for JSON parsing)
- RBAC: read/delete **Microsoft.HybridCompute/machines** and **connectedmachine/extensions**; read/delete policy assignments (optional)
- Admin rights on target servers for `azcmagent disconnect`

## Contributing
PRs welcome! Keep examples idempotent and safe-by-default. Prefer parameters over hard-coded values.

## License
Choose your org standard (MIT recommended for public).


