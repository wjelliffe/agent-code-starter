param(
  [Parameter(Mandatory=$true)][string]$WorkKey,
  [ValidateSet('inplace','worktree')][string]$Mode = 'inplace'
)
. "$PSScriptRoot/common.ps1"
Assert-AcsCommand 'git'
$root = Get-AcsRepoRoot
$slug = ConvertTo-AcsSlug $WorkKey
$branch = "$(Get-AcsBranchPrefix)$slug"
$trunk = Get-AcsTrunkBranch
$status = (& git -C $root status --porcelain)
if (-not [string]::IsNullOrWhiteSpace(($status -join "`n"))) { throw 'refusing setup with a dirty working tree' }
& git -C $root show-ref --verify --quiet "refs/heads/$trunk"
if ($LASTEXITCODE -ne 0) { throw "trunk branch not found: $trunk" }

if ($Mode -eq 'inplace') {
  & git -C $root show-ref --verify --quiet "refs/heads/$branch"
  if ($LASTEXITCODE -eq 0) {
    & git -C $root checkout $branch | Out-Null
  } else {
    & git -C $root checkout $trunk | Out-Null
    & git -C $root checkout -b $branch | Out-Null
  }
  Write-Output "ACS_BRANCH=$branch"
  Write-Output "ACS_PATH=$root"
  Write-Output "ACS_TRUNK=$trunk"
  exit 0
}

$repoName = Split-Path $root -Leaf
$parent = Split-Path $root -Parent
$worktreePath = Join-Path $parent "$repoName-$slug"
if (Test-Path $worktreePath) {
  $existing = (& git -C $worktreePath branch --show-current).Trim()
  if ($existing -ne $branch) { throw "existing worktree is on $existing, expected $branch" }
} else {
  & git -C $root show-ref --verify --quiet "refs/heads/$branch"
  if ($LASTEXITCODE -eq 0) {
    & git -C $root worktree add $worktreePath $branch | Out-Null
  } else {
    & git -C $root worktree add -b $branch $worktreePath $trunk | Out-Null
  }
}
Write-Output "ACS_BRANCH=$branch"
Write-Output "ACS_PATH=$worktreePath"
Write-Output "ACS_TRUNK=$trunk"
