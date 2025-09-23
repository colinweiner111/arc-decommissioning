<#
.SYNOPSIS
  List (and optionally delete) Arc-related Azure Policy assignments to reduce compliance noise.
.DESCRIPTION
  Heuristic match on displayName for: Arc, ArcBox, Change Tracking, AzureMonitorWindowsAgent/AMA, MDE.Windows.
  Use -Regex to override. Use -Scope to target MG/subscription/RG scope; default is current subscription.
  Use -Delete to remove matched assignments (supports -WhatIf).
.EXAMPLE
  ./policy-hygiene.ps1
.EXAMPLE
  ./policy-hygiene.ps1 -Scope /subscriptions/00000000-0000-0000-0000-000000000000 -Delete -WhatIf
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
  [string]$Scope,
  [string]$Regex = '(?i)(\bArc\b|ArcBox|Change\s*Tracking|AzureMonitorWindowsAgent|AMA\b|MDE\.Windows)',
  [switch]$Delete
)

# Ensure az is logged in
az account show > $null 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Error "Please 'az login' first."
  exit 1
}

$commonArgs = @()
if ($Scope) { $commonArgs += @('--scope', $Scope) }

$json = az policy assignment list @commonArgs --disable-scope-strict-match 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to list policy assignments. Check your RBAC and scope."
  exit 2
}

$assignments = $null
try { $assignments = $json | ConvertFrom-Json } catch { }
if (-not $assignments) {
  Write-Host "No assignments returned."
  exit 0
}

$matches = $assignments | Where-Object { $_.displayName -match $Regex }
if (-not $matches) {
  Write-Host "No Arc-related assignments matched the regex: $Regex"
  exit 0
}

Write-Host "Matched assignments:" -ForegroundColor Cyan
$matches | Select-Object name, displayName, scope | Format-Table -AutoSize

if ($Delete) {
  foreach ($a in $matches) {
    $n = $a.name
    $s = $a.scope
    if ($PSCmdlet.ShouldProcess("$s/$n","az policy assignment delete")) {
      az policy assignment delete --name $n --scope $s
      if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to delete assignment $n at $s"
      } else {
        Write-Host "Deleted assignment $n at $s"
      }
    }
  }
} else {
  Write-Host "`nRun with -Delete (and optionally -WhatIf) to remove the above assignments."
}
