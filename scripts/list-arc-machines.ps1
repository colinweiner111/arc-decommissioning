<#
.SYNOPSIS
  List Azure Arc machines in the current tenant/subscription context via Azure Resource Graph.

.EXAMPLE
  ./list-arc-machines.ps1
.EXAMPLE
  ./list-arc-machines.ps1 -SubscriptionId 00000000-0000-0000-0000-000000000000 -CsvPath .\arc-machines.csv
#>
param(
  [string]$SubscriptionId,
  [string]$CsvPath
)

# Ensure az is logged in
az account show > $null 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Error "Please 'az login' first."
  exit 1
}

if ($SubscriptionId) {
  az account set --subscription $SubscriptionId | Out-Null
}

$query = @"
resources
| where type =~ 'microsoft.hybridcompute/machines'
| project name, resourceGroup, subscriptionId, location, id
"@

$json = az graph query -q $query --first 1000 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to query Resource Graph. Ensure 'az extension add --name resource-graph'."
  exit 2
}

$result = ($json | ConvertFrom-Json).data
if (-not $result) {
  Write-Host "No Arc machines found."
  exit 0
}

$result | Format-Table -AutoSize

if ($CsvPath) {
  $result | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
  Write-Host "Saved CSV to $CsvPath"
}
