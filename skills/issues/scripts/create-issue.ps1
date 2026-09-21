param(
  [Parameter(Mandatory=$true)][string]$Title,
  [Parameter(Mandatory=$true)][string]$BodyFile,
  [string[]]$Labels = @()
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh is required' }
if (-not (Test-Path $BodyFile)) { throw 'body file not found' }
$args = @('issue','create','--title',$Title,'--body-file',$BodyFile)
foreach ($label in $Labels) { $args += @('--label',$label) }
$url = (& gh @args).Trim()
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$number = (& gh issue view $url --json number --jq '.number').Trim()
Write-Output "ACS_ISSUE_NUMBER=$number"
Write-Output "ACS_ISSUE_URL=$url"
