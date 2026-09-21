param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Path)) { throw 'plan file not found' }
$text = Get-Content $Path -Raw
$missing = @()
foreach ($heading in @('Approach','Touch points','Invariants','Sequence','Tests','Risks')) {
  if ($text -notmatch "(?im)^#{1,6}\s+$([regex]::Escape($heading))(\s|$)") { $missing += $heading }
}
$statusMatch = [regex]::Match($text, '(?im)^PLAN_STATUS:\s*(READY|BLOCKED)\s*$')
if (-not $statusMatch.Success) { $missing += 'PLAN_STATUS: READY|BLOCKED' }
if ($missing.Count -gt 0) {
  foreach ($item in $missing) { Write-Output "PLAN_MISSING=$item" }
  Write-Output 'PLAN_VALID=false'
  exit 1
}
Write-Output 'PLAN_VALID=true'
Write-Output "PLAN_STATUS=$($statusMatch.Groups[1].Value.ToUpperInvariant())"
