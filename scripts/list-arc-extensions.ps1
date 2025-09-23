<#
.SYNOPSIS
  List extensions installed on a specific Azure Arc machine.

.EXAMPLE
  ./list-arc-extensions.ps1 -MachineName my-arc-server -ResourceGroup rg-arc
#>
param(
  [Parameter(Mandatory=$true)][string]$MachineName,
  [Parameter(Mandatory=$true)][string]$ResourceGroup
)

az connectedmachine extension list --machine-name $MachineName --resource-group $ResourceGroup --output table
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to list extensions. Check machine name and resource group."
  exit 1
}
