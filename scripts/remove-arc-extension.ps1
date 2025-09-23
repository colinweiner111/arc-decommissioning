<#
.SYNOPSIS
  Remove one or more Azure Arc extensions from a connected machine.

.EXAMPLE
  ./remove-arc-extension.ps1 -MachineName my-arc -ResourceGroup rg -ExtensionName MDE.Windows
.EXAMPLE
  ./remove-arc-extension.ps1 -MachineName my-arc -ResourceGroup rg -CommonSet
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [Parameter(Mandatory=$true)][string]$MachineName,
  [Parameter(Mandatory=$true)][string]$ResourceGroup,
  [string]$ExtensionName,
  [switch]$CommonSet  # Removes a small set: MDE.Windows, AzureMonitorWindowsAgent, ChangeTracking
)

$targets = @()
if ($CommonSet) {
  $targets = @("MDE.Windows","AzureMonitorWindowsAgent","ChangeTracking")
} elseif ($ExtensionName) {
  $targets = @($ExtensionName)
} else {
  throw "Specify -ExtensionName or -CommonSet."
}

foreach ($ext in $targets) {
  if ($PSCmdlet.ShouldProcess("$MachineName/$ext","az connectedmachine extension delete")) {
    az connectedmachine extension delete `
      --name $ext `
      --machine-name $MachineName `
      --resource-group $ResourceGroup `
      --yes
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Failed to remove extension '$ext' on '$MachineName'."
    } else {
      Write-Host "Removed extension '$ext' on '$MachineName'."
    }
  }
}
