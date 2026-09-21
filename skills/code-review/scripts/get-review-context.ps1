param([Parameter(Mandatory=$true)][int]$PrNumber)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh is required' }
$repo = (& gh repo view --json nameWithOwner --jq '.nameWithOwner').Trim()
Write-Output '=== PR ==='
& gh pr view $PrNumber --json number,title,body,url,state,baseRefName,headRefName,author,labels,statusCheckRollup
Write-Output ''
Write-Output '=== DIFF ==='
& gh pr diff $PrNumber
Write-Output ''
Write-Output '=== INLINE REVIEW COMMENTS ==='
& gh api "repos/$repo/pulls/$PrNumber/comments"
Write-Output ''
Write-Output '=== CONVERSATION COMMENTS ==='
& gh api "repos/$repo/issues/$PrNumber/comments"
