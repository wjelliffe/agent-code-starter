param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Path)) { throw 'issue body file not found' }
$text = Get-Content $Path -Raw
$missing = @()
if ($text -notmatch '(?im)^#{1,6}\s+(Problem|Objective)(\s|$)') { $missing += 'Problem or Objective heading' }
if ($text -notmatch '(?im)^#{1,6}\s+Acceptance Criteria(\s|$)') { $missing += 'Acceptance Criteria heading' }
if ($text -notmatch '(?im)^[-*]\s+.+$') { $missing += 'at least one actionable bullet' }
if ($missing.Count -gt 0) {
  foreach ($item in $missing) { Write-Output "DOR_MISSING=$item" }
  Write-Output 'DOR_STATUS=BLOCKED'
  exit 1
}
Write-Output 'DOR_STATUS=READY'
