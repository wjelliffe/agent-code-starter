$ErrorActionPreference = 'Stop'
$root = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($root)) { throw 'summarize-diff.ps1 must run inside a git repository' }
Set-Location $root.Trim()
Write-Output '=== ACS DIFF SUMMARY ==='
Write-Output "Branch: $((& git branch --show-current).Trim())"
Write-Output ''
Write-Output '--- status ---'
& git status --short
Write-Output ''
Write-Output '--- diff stat ---'
& git diff --stat
Write-Output ''
Write-Output '--- changed files ---'
$files = @(& git diff --name-only) + @(& git ls-files --others --exclude-standard)
$files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
