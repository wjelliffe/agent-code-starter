param([Parameter(Mandatory=$true)][int]$ParentNumber,[Parameter(Mandatory=$true)][int]$ChildNumber)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh is required' }
$repo = (& gh repo view --json nameWithOwner --jq '.nameWithOwner').Trim()
$childId = (& gh api "repos/$repo/issues/$ChildNumber" --jq '.id').Trim()
& gh api --method POST "repos/$repo/issues/$ParentNumber/sub_issues" -F "sub_issue_id=$childId" | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output "ACS_PARENT=$ParentNumber"
Write-Output "ACS_CHILD=$ChildNumber"
Write-Output 'ACS_LINKED=true'
