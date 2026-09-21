param(
  [Parameter(Mandatory=$true)][ValidateSet('merge','pr','update-pr','merge-pr')][string]$Mode,
  [string]$Title = 'Agent Code Starter change',
  [int]$PrNumber = 0
)
. "$PSScriptRoot/common.ps1"
Assert-AcsCommand 'git'
$root = Get-AcsRepoRoot
$trunk = Get-AcsTrunkBranch
$current = (& git -C $root branch --show-current).Trim()

function Commit-AcsChanges([string]$Message) {
  if ([string]::IsNullOrWhiteSpace($current)) { throw 'refusing finalization from detached HEAD' }
  if ($current -eq $trunk) { throw "refusing to commit or finalize directly on trunk ($trunk)" }
  & git -C $root add -A
  & git -C $root diff --cached --quiet
  if ($LASTEXITCODE -eq 0) { return $false }
  & git -C $root commit -m $Message | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
  return $true
}

switch ($Mode) {
  'pr' {
    Assert-AcsCommand 'gh'
    if (-not (Commit-AcsChanges "feat: $Title")) { throw 'no changes to finalize' }
    & git -C $root push -u origin $current | Out-Null
    Push-Location $root
    try {
      $url = (& gh pr create --title $Title --body 'Implemented with Agent Code Starter.' --base $trunk --head $current).Trim()
      $number = (& gh pr view $url --json number --jq '.number').Trim()
    } finally { Pop-Location }
    Write-Output 'ACS_MODE=pr'
    Write-Output "ACS_PR_NUMBER=$number"
    Write-Output "ACS_PR_URL=$url"
    Write-Output "ACS_BRANCH=$current"
  }
  'update-pr' {
    Assert-AcsCommand 'gh'
    if ($PrNumber -le 0) { throw 'update-pr requires a numeric PR number' }
    Push-Location $root
    try {
      $state = (& gh pr view $PrNumber --json state --jq '.state').Trim()
      $head = (& gh pr view $PrNumber --json headRefName --jq '.headRefName').Trim()
    } finally { Pop-Location }
    if ($state -ne 'OPEN') { throw "refusing to update PR #$PrNumber`: state is $state" }
    if ($head -ne $current) { throw "refusing to update PR #$PrNumber`: current branch $current is not PR head $head" }
    $updated = Commit-AcsChanges "fix: $Title"
    if ($updated) { & git -C $root push origin $current | Out-Null }
    Write-Output 'ACS_MODE=update-pr'
    Write-Output "ACS_PR_NUMBER=$PrNumber"
    Write-Output "ACS_UPDATED=$($updated.ToString().ToLowerInvariant())"
  }
  'merge-pr' {
    Assert-AcsCommand 'gh'
    if ($PrNumber -le 0) { throw 'merge-pr requires a numeric PR number' }
    Push-Location $root
    try {
      $state = (& gh pr view $PrNumber --json state --jq '.state').Trim()
      if ($state -ne 'OPEN') { throw "refusing to merge PR #$PrNumber`: state is $state" }
      & gh pr merge $PrNumber --squash
      if ($LASTEXITCODE -ne 0) { throw "failed to merge PR #$PrNumber" }
    } finally { Pop-Location }
    Write-Output 'ACS_MODE=merge-pr'
    Write-Output "ACS_PR_NUMBER=$PrNumber"
    Write-Output 'ACS_MERGED=true'
  }
  'merge' {
    if (-not (Commit-AcsChanges "feat: $Title")) { throw 'no changes to finalize' }
    $branch = $current
    & git -C $root checkout $trunk | Out-Null
    & git -C $root merge --ff-only $branch | Out-Null
    if ($LASTEXITCODE -ne 0) {
      & git -C $root merge $branch | Out-Null
      if ($LASTEXITCODE -ne 0) { throw 'git merge failed' }
    }
    & git -C $root branch -d $branch | Out-Null
    Write-Output 'ACS_MODE=merge'
    Write-Output 'ACS_MERGED=true'
    Write-Output "ACS_TRUNK=$trunk"
  }
}
