param([Parameter(Mandatory=$true)][int]$PrNumber,[Parameter(Mandatory=$true)][string]$ReviewFile)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ReviewFile)) { throw 'review file not found' }
& "$PSScriptRoot/validate-review.ps1" -Path $ReviewFile | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh is required' }
& gh pr review $PrNumber --comment --body-file $ReviewFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output 'ACS_REVIEW_POSTED=true'
Write-Output "ACS_PR_NUMBER=$PrNumber"
