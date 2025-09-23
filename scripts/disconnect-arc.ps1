<#
.SYNOPSIS
  Azure-side delete of Arc machine resources (fallback when the server is unreachable).
  Best practice: run 'azcmagent disconnect' ON THE SERVER when possible.

.EXAMPLE
  ./disconnect-arc.ps1 -MachineName my-arc -ResourceGroup rg-arc
.EXAMPLE
  ./disconnect-arc.ps1 -CsvPath .\arc-machines.csv
    CSV must contain columns: name, resourceGroup
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$MachineName,
  [string]$ResourceGroup,
  [string]$CsvPath
)

$items = @()
if ($CsvPath) {
  if (-not (Test-Path $CsvPath)) { throw "CSV not found: $CsvPath" }
  $items = Import-Csv -Path $CsvPath
} elseif ($MachineName -and $ResourceGroup) {
  $items = @([pscustomobject]@{ name=$MachineName; resourceGroup=$ResourceGroup })
} else {
  throw "Provide -MachineName and -ResourceGroup OR -CsvPath."
}

foreach ($row in $items) {
  $name = $row.name
  $rg = $row.resourceGroup
  if (-not $name -or -not $rg) {
    Write-Warning "Skipping row with missing name/resourceGroup."
    continue
  }
  if ($PSCmdlet.ShouldProcess("$rg/$name","az connectedmachine delete")) {
    az connectedmachine delete --name $name --resource-group $rg --yes
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Failed to delete Arc resource $name in $rg."
    } else {
      Write-Host "Deleted Arc resource $name in $rg."
    }
  }
}

Write-Host "`nNote: For a CLEAN disconnect, run this ON THE SERVER:"
Write-Host "  azcmagent disconnect"
