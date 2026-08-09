# Full first-time setup on Windows when Ruby/Node are available on PATH
# (WSL2 recommended for Rails). Starts Docker deps, then bundle/pnpm/db.
# Usage: .\deploy\dev-setup.ps1

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $Root

& (Join-Path $PSScriptRoot 'dev-up.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

function Require-Cmd($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Missing '$name'. $hint"
  }
}

Require-Cmd ruby 'Install Ruby 3.4.4 (rbenv/WSL recommended). See .ruby-version'
Require-Cmd bundle 'gem install bundler -v 2.5.16'
Require-Cmd pnpm 'corepack enable; corepack prepare pnpm@latest --activate (Node 24.x)'

Write-Host '==> bundle install'
bundle check
if ($LASTEXITCODE -ne 0) { bundle install; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }

Write-Host '==> pnpm install'
pnpm install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '==> db:prepare'
bundle exec rails db:prepare
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'Ready. Start: pnpm dev'
Write-Host 'App: http://localhost:3001'
Write-Host 'Day-to-day coding uses hot reload. Use build-push only for test/dev/custom.'
