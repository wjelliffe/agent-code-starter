$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$passes = 0

function Pass([string]$Name) { $script:passes++; Write-Output "ok - $Name" }
function Fail([string]$Name) { throw "not ok - $Name" }
function Assert-Contains([string]$Text,[string]$Needle,[string]$Name) { if (-not $Text.Contains($Needle)) { Fail $Name } }

$codex = Get-Content (Join-Path $Root '.codex-plugin/plugin.json') -Raw | ConvertFrom-Json
$claude = Get-Content (Join-Path $Root '.claude-plugin/plugin.json') -Raw | ConvertFrom-Json
if ($codex.version -ne '3.0.0' -or $claude.version -ne '3.0.0') { Fail 'plugin versions' }
if ($codex.version -ne $claude.version) { Fail 'version parity' }
Pass 'plugin versions are synchronized'

$skills = @('issues','plan','implement','code-review','sdlc-do')
foreach ($skill in $skills) {
  if (-not (Test-Path (Join-Path $Root "skills/$skill/SKILL.md"))) { Fail "missing skill $skill" }
}
$found = @(Get-ChildItem (Join-Path $Root 'skills') -Filter SKILL.md -Recurse | Where-Object { $_.Directory.Parent.Name -eq 'skills' })
if ($found.Count -ne 5) { Fail 'expected five invocable entries' }
Pass 'four skills plus workflow facade are present'

if (Test-Path (Join-Path $Root 'runtime')) { Fail 'legacy root runtime directory still exists' }
if (@(Get-ChildItem $Root -Filter '*.py' -Recurse -File).Count -ne 0) { Fail 'Python files remain in repository' }
Pass 'runtime is bundled with skills and has no Python dependency'

$psScripts = @(Get-ChildItem (Join-Path $Root 'skills') -Filter '*.ps1' -Recurse -File)
foreach ($script in $psScripts) {
  try { [void][scriptblock]::Create((Get-Content $script.FullName -Raw)) } catch { Fail "invalid PowerShell syntax: $($script.FullName): $_" }
  $bashPair = [IO.Path]::ChangeExtension($script.FullName, '.sh')
  if (-not (Test-Path $bashPair)) { Fail "missing Bash pair for $($script.FullName)" }
}
Pass 'PowerShell scripts parse and every helper has a Bash pair'

$temp = Join-Path ([IO.Path]::GetTempPath()) ("acs-tests-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
  $plan = Join-Path $temp 'plan.md'
  @'
## Approach
Do it.
## Touch points
- src
## Invariants
- preserve behavior
## Sequence
- edit
## Tests
- run tests
## Risks
- none
PLAN_STATUS: READY
'@ | Set-Content $plan
  $out = & (Join-Path $Root 'skills/plan/scripts/validate-plan.ps1') -Path $plan | Out-String
  Assert-Contains $out 'PLAN_STATUS=READY' 'plan validator'
  Pass 'plan contract validator accepts a complete plan'

  $review = Join-Path $temp 'review.md'
  @'
## Findings
No blockers found.
VERDICT: APPROVE
'@ | Set-Content $review
  $out = & (Join-Path $Root 'skills/code-review/scripts/validate-review.ps1') -Path $review | Out-String
  Assert-Contains $out 'VERDICT: APPROVE' 'review validator'
  Pass 'review contract validator accepts a valid verdict'

  $repo = Join-Path $temp 'repo'
  New-Item -ItemType Directory -Path $repo | Out-Null
  & git -C $repo init -b main | Out-Null
  if ($LASTEXITCODE -ne 0) {
    & git -C $repo init | Out-Null
    & git -C $repo checkout -b main | Out-Null
  }
  & git -C $repo config user.email test@example.com
  & git -C $repo config user.name 'ACS Tests'
  Set-Content (Join-Path $repo 'README.md') 'fixture'
  & git -C $repo add README.md
  & git -C $repo commit -m initial | Out-Null

  Push-Location $repo
  try {
    $ctl = Join-Path $Root 'skills/sdlc-do/scripts/sdlc.ps1'
    $out = & $ctl -Command start -RunId happy issue-107 | Out-String
    Assert-Contains $out 'State: PLAN_REQUIRED' 'sdlc start'
    $out = & $ctl -Command approve-plan -RunId happy | Out-String
    Assert-Contains $out 'State: IMPLEMENT_REQUIRED' 'approve plan'
    & $ctl -Command complete -RunId happy implement | Out-Null
    & $ctl -Command complete -RunId happy verify pass | Out-Null
    & $ctl -Command complete -RunId happy create-pr 123 | Out-Null
    $out = & $ctl -Command complete -RunId happy review approve | Out-String
    Assert-Contains $out 'State: MERGE_REQUIRED' 'review approve'
    $out = & $ctl -Command complete -RunId happy merge | Out-String
    Assert-Contains $out 'State: DONE' 'merge done'
    Pass 'SDLC happy path reaches DONE'

    & $ctl -Command start -RunId bounded issue-108 | Out-Null
    & $ctl -Command approve-plan -RunId bounded | Out-Null
    & $ctl -Command complete -RunId bounded implement | Out-Null
    & $ctl -Command complete -RunId bounded verify pass | Out-Null
    & $ctl -Command complete -RunId bounded create-pr 124 | Out-Null
    & $ctl -Command complete -RunId bounded review blockers | Out-Null
    & $ctl -Command complete -RunId bounded remediate | Out-Null
    & $ctl -Command complete -RunId bounded reverify pass | Out-Null
    $out = & $ctl -Command complete -RunId bounded review blockers | Out-String
    Assert-Contains $out 'State: BLOCKED' 'final blocker state'
    Assert-Contains $out 'Review passes: 2/2' 'review pass cap'
    $failed = $false
    try { & $ctl -Command complete -RunId bounded remediate | Out-Null } catch { $failed = $true }
    if (-not $failed) { Fail 'blocked workflow permitted third remediation' }
    Pass 'second blocking review terminates with no remediation loop'
  } finally { Pop-Location }
} finally {
  Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
}
Write-Output "1..$passes"
