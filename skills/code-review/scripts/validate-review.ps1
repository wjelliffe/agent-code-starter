param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Path)) { throw 'review file not found' }
$lines = @(Get-Content $Path | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($lines.Count -eq 0) { throw 'review file is empty' }
$last = $lines[-1].Trim()
if ($last -notin @('VERDICT: APPROVE','VERDICT: BLOCKERS')) {
  Write-Output 'REVIEW_VALID=false'
  Write-Output 'REVIEW_ERROR=last non-empty line must be VERDICT: APPROVE or VERDICT: BLOCKERS'
  exit 1
}
$text = Get-Content $Path -Raw
if ($text -notmatch '(?im)^#{1,6}\s+Findings(\s|$)') {
  Write-Output 'REVIEW_VALID=false'
  Write-Output 'REVIEW_ERROR=missing Findings heading'
  exit 1
}
Write-Output 'REVIEW_VALID=true'
Write-Output $last
