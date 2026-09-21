param(
  [Parameter(Mandatory=$true)][ValidateSet('start','status','approve-plan','complete','block')][string]$Command,
  [Parameter(Mandatory=$true)][string]$RunId,
  [Parameter(ValueFromRemainingArguments=$true)][string[]]$Remaining
)
$ErrorActionPreference = 'Stop'
if ($RunId -notmatch '^[A-Za-z0-9._-]+$') { throw 'run-id may contain only letters, numbers, dot, underscore, and hyphen' }
$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) { throw 'sdlc.ps1 must run inside a git repository' }
$repoRoot = $repoRoot.Trim()
$common = (& git -C $repoRoot rev-parse --git-common-dir).Trim()
if (-not [IO.Path]::IsPathRooted($common)) { $common = Join-Path $repoRoot $common }
$runDir = Join-Path $common "agent-code-starter/runs/$RunId"

function Read-Field([string]$Name) {
  $path = Join-Path $runDir $Name
  if (Test-Path $path) { return (Get-Content $path -Raw).TrimEnd("`r","`n") }
  return ''
}
function Write-Field([string]$Name,[string]$Value) {
  New-Item -ItemType Directory -Force -Path $runDir | Out-Null
  Set-Content -Path (Join-Path $runDir $Name) -Value $Value -NoNewline
}
function Require-Run {
  if (-not (Test-Path $runDir)) { throw "unknown ACS SDLC run: $RunId" }
}
function Require-State([string]$Expected) {
  $actual = Read-Field 'STATE'
  if ($actual -ne $Expected) { throw "illegal transition: expected $Expected, current state is $actual" }
}
function Set-Blocked([string]$Reason) {
  Write-Field 'STATE' 'BLOCKED'
  Write-Field 'BLOCK_REASON' $Reason
}
function Get-Next([string]$State) {
  switch ($State) {
    'PLAN_REQUIRED' { 'Produce and validate the technical plan; then ask for plan approval.' }
    'IMPLEMENT_REQUIRED' { 'Implement the approved plan in the prepared branch/worktree.' }
    'VERIFY_REQUIRED' { 'Run deterministic checks/tests and assess acceptance criteria.' }
    'CREATE_PR_REQUIRED' { 'Create the pull request and record its number.' }
    'REVIEW_1_REQUIRED' { 'Run one fresh adversarial review pass.' }
    'REMEDIATE_REQUIRED' { 'Address valid findings on the existing PR.' }
    'REVERIFY_REQUIRED' { 'Re-run deterministic verification once.' }
    'REVIEW_2_REQUIRED' { 'Run the final fresh review pass. This is the last review pass.' }
    'MERGE_REQUIRED' { 'Merge the reviewed PR.' }
    'DONE' { 'Feature complete.' }
    'BLOCKED' { "Stop and surface blocker: $(Read-Field 'BLOCK_REASON')" }
    default { 'Unknown state.' }
  }
}
function Show-Status {
  Require-Run
  $state = Read-Field 'STATE'
  $reviews = Read-Field 'REVIEW_PASS'; if ([string]::IsNullOrWhiteSpace($reviews)) { $reviews = '0' }
  Write-Output "ACS SDLC $RunId"
  Write-Output "Target: $(Read-Field 'TARGET')"
  Write-Output "State: $state"
  Write-Output "Review passes: $reviews/2"
  $pr = Read-Field 'PR_NUMBER'; if (-not [string]::IsNullOrWhiteSpace($pr)) { Write-Output "PR: #$pr" }
  Write-Output "Next: $(Get-Next $state)"
}

switch ($Command) {
  'start' {
    if (Test-Path $runDir) { throw "run already exists: $RunId" }
    $target = ($Remaining -join ' ').Trim(); if ([string]::IsNullOrWhiteSpace($target)) { $target = $RunId }
    New-Item -ItemType Directory -Force -Path $runDir | Out-Null
    Write-Field 'TARGET' $target
    Write-Field 'STATE' 'PLAN_REQUIRED'
    Write-Field 'REVIEW_PASS' '0'
    Show-Status
  }
  'status' { Show-Status }
  'approve-plan' {
    Require-Run; Require-State 'PLAN_REQUIRED'; Write-Field 'STATE' 'IMPLEMENT_REQUIRED'; Show-Status
  }
  'complete' {
    Require-Run
    $phase = if ($Remaining.Count -gt 0) { $Remaining[0] } else { '' }
    $result = if ($Remaining.Count -gt 1) { $Remaining[1] } else { '' }
    switch ($phase) {
      'implement' { Require-State 'IMPLEMENT_REQUIRED'; Write-Field 'STATE' 'VERIFY_REQUIRED' }
      'verify' {
        Require-State 'VERIFY_REQUIRED'
        if ($result -eq 'pass') { Write-Field 'STATE' 'CREATE_PR_REQUIRED' }
        elseif ($result -eq 'fail') { Set-Blocked 'initial verification failed' }
        else { throw 'verify result must be pass or fail' }
      }
      'create-pr' {
        Require-State 'CREATE_PR_REQUIRED'
        if ($result -notmatch '^\d+$') { throw 'create-pr requires a numeric PR number' }
        Write-Field 'PR_NUMBER' $result; Write-Field 'STATE' 'REVIEW_1_REQUIRED'
      }
      'review' {
        $state = Read-Field 'STATE'
        if ($result -notin @('approve','blockers')) { throw 'review result must be approve or blockers' }
        if ($state -eq 'REVIEW_1_REQUIRED') {
          Write-Field 'REVIEW_PASS' '1'
          if ($result -eq 'approve') { Write-Field 'STATE' 'MERGE_REQUIRED' } else { Write-Field 'STATE' 'REMEDIATE_REQUIRED' }
        } elseif ($state -eq 'REVIEW_2_REQUIRED') {
          Write-Field 'REVIEW_PASS' '2'
          if ($result -eq 'approve') { Write-Field 'STATE' 'MERGE_REQUIRED' } else { Set-Blocked 'final review still has substantive blockers' }
        } else { throw "illegal transition: review cannot complete from $state" }
      }
      'remediate' { Require-State 'REMEDIATE_REQUIRED'; Write-Field 'STATE' 'REVERIFY_REQUIRED' }
      'reverify' {
        Require-State 'REVERIFY_REQUIRED'
        if ($result -eq 'pass') { Write-Field 'STATE' 'REVIEW_2_REQUIRED' }
        elseif ($result -eq 'fail') { Set-Blocked 'verification after remediation failed' }
        else { throw 'reverify result must be pass or fail' }
      }
      'merge' { Require-State 'MERGE_REQUIRED'; Write-Field 'STATE' 'DONE' }
      default { throw "unknown completion phase: $phase" }
    }
    Show-Status
  }
  'block' {
    Require-Run
    if ((Read-Field 'STATE') -eq 'DONE') { throw 'cannot block a completed run' }
    $reason = ($Remaining -join ' ').Trim(); if ([string]::IsNullOrWhiteSpace($reason)) { $reason = 'blocked by operator' }
    Set-Blocked $reason
    Show-Status
  }
}
