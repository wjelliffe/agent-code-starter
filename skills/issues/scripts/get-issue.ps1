param([Parameter(Mandatory=$true)][int]$IssueNumber)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh is required' }
& gh issue view $IssueNumber --json number,title,body,url,state,labels,assignees,author,comments
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
