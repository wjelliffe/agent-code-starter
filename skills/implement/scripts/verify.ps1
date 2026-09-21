param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('checks','tests')]
  [string]$Kind
)
. "$PSScriptRoot/common.ps1"
$root = Get-AcsRepoRoot
Set-Location $root

function Invoke-AcsCommand([string]$Command) {
  Write-Output "ACS_RUN=$Command"
  Invoke-Expression $Command
  if ($LASTEXITCODE -ne 0) {
    Write-Output 'ACS_STATUS=FAIL'
    Write-Output "ACS_FAILED_COMMAND=$Command"
    exit $LASTEXITCODE
  }
}

$configKey = if ($Kind -eq 'checks') { 'check' } else { 'test' }
$configured = @(Get-AcsConfigValues $configKey)
if ($configured.Count -gt 0) {
  foreach ($command in $configured) { Invoke-AcsCommand $command }
  Write-Output 'ACS_STATUS=PASS'
  Write-Output 'ACS_SOURCE=config'
  exit 0
}

$count = 0
function Invoke-Auto([string]$Command) {
  Invoke-AcsCommand $Command
  $script:count++
}

$package = $null
if (Test-Path 'package.json') {
  try { $package = Get-Content 'package.json' -Raw | ConvertFrom-Json } catch { $package = $null }
}
$pm = ''
if ($package) {
  if ((Test-Path 'pnpm-lock.yaml') -and (Get-Command pnpm -ErrorAction SilentlyContinue)) { $pm = 'pnpm' }
  elseif ((Test-Path 'yarn.lock') -and (Get-Command yarn -ErrorAction SilentlyContinue)) { $pm = 'yarn' }
  elseif (((Test-Path 'bun.lockb') -or (Test-Path 'bun.lock')) -and (Get-Command bun -ErrorAction SilentlyContinue)) { $pm = 'bun' }
  elseif (Get-Command npm -ErrorAction SilentlyContinue) { $pm = 'npm' }
}

function Test-JsScript([string]$Name) {
  if (-not $package -or -not $package.scripts) { return $false }
  return $null -ne $package.scripts.PSObject.Properties[$Name]
}
function Invoke-JsScript([string]$Name) {
  if ($pm -eq 'yarn') { Invoke-Auto "yarn $Name" }
  elseif ($pm -eq 'bun') { Invoke-Auto "bun run $Name" }
  elseif ($pm) { Invoke-Auto "$pm run $Name" }
}

if ($Kind -eq 'checks') {
  if ($pm) {
    foreach ($name in @('typecheck','lint','check','build')) { if (Test-JsScript $name) { Invoke-JsScript $name } }
  }
  if ((Test-Path 'go.mod') -and (Get-Command go -ErrorAction SilentlyContinue)) { Invoke-Auto 'go vet ./...' }
  if ((Test-Path 'Cargo.toml') -and (Get-Command cargo -ErrorAction SilentlyContinue)) { Invoke-Auto 'cargo check --all-targets' }
} else {
  if ($pm) {
    foreach ($name in @('test','test:unit','test:integration')) { if (Test-JsScript $name) { Invoke-JsScript $name } }
  }
  $pythonTests = @(Get-ChildItem tests -Filter '*.py' -Recurse -ErrorAction SilentlyContinue)
  if ($pythonTests.Count -gt 0) {
    if (Get-Command python -ErrorAction SilentlyContinue) { Invoke-Auto 'python -m unittest discover -s tests' }
    elseif (Get-Command py -ErrorAction SilentlyContinue) { Invoke-Auto 'py -m unittest discover -s tests' }
  }
  if ((Test-Path 'go.mod') -and (Get-Command go -ErrorAction SilentlyContinue)) { Invoke-Auto 'go test ./...' }
  if ((Test-Path 'Cargo.toml') -and (Get-Command cargo -ErrorAction SilentlyContinue)) { Invoke-Auto 'cargo test --all-targets' }
}

if ($count -eq 0) {
  Write-Output 'ACS_STATUS=NONE_FOUND'
  Write-Output 'ACS_SOURCE=auto'
} else {
  Write-Output 'ACS_STATUS=PASS'
  Write-Output 'ACS_SOURCE=auto'
  Write-Output "ACS_COMMANDS=$count"
}
