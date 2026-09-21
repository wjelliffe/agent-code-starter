Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-AcsRepoRoot {
  $root = (& git rev-parse --show-toplevel 2>$null)
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($root)) {
    throw 'Agent Code Starter must run inside a git repository'
  }
  return $root.Trim()
}

function Get-AcsConfigPath {
  return (Join-Path (Get-AcsRepoRoot) '.agent-code')
}

function Get-AcsConfigValues([string]$Key) {
  $path = Get-AcsConfigPath
  if (-not (Test-Path $path)) { return @() }
  $prefix = "$Key="
  return @(Get-Content $path | Where-Object { $_.StartsWith($prefix) } | ForEach-Object { $_.Substring($prefix.Length) })
}

function Get-AcsConfigFirst([string]$Key) {
  $values = @(Get-AcsConfigValues $Key)
  if ($values.Count -eq 0) { return '' }
  return $values[0]
}

function Get-AcsTrunkBranch {
  $configured = Get-AcsConfigFirst 'trunk_branch'
  if (-not [string]::IsNullOrWhiteSpace($configured)) { return $configured }
  $root = Get-AcsRepoRoot
  $detected = (& git -C $root symbolic-ref refs/remotes/origin/HEAD 2>$null)
  if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($detected)) {
    return ($detected -replace '^refs/remotes/origin/', '').Trim()
  }
  & git -C $root show-ref --verify --quiet refs/heads/main
  if ($LASTEXITCODE -eq 0) { return 'main' }
  return 'master'
}

function Get-AcsBranchPrefix {
  $configured = Get-AcsConfigFirst 'branch_prefix'
  if ([string]::IsNullOrWhiteSpace($configured)) { $configured = 'agent/' }
  if (-not $configured.EndsWith('/')) { $configured += '/' }
  return $configured
}

function ConvertTo-AcsSlug([string]$Value) {
  $slug = $Value.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
  $slug = $slug.Trim('-')
  if ($slug.Length -gt 72) { $slug = $slug.Substring(0, 72).TrimEnd('-') }
  if ([string]::IsNullOrWhiteSpace($slug)) { return 'work' }
  return $slug
}

function Assert-AcsCommand([string]$Command) {
  if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) { throw "$Command is required" }
}
