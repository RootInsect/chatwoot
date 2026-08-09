# Start Chatwoot full-stack local Docker (bind-mount source for hot reload).
# Usage: .\deploy\dev-docker-up.ps1
# No local Ruby required.

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $Root

$ComposeFile = Join-Path $Root 'deploy\compose.dev.yml'
$DepsCompose = Join-Path $Root 'deploy\compose.dev-deps.yml'
$EnvExample = Join-Path $Root 'deploy\env\development.docker.env.example'
$EnvFile = Join-Path $Root '.env'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw 'Need Docker Desktop installed and running.'
}

$depsIds = docker compose -f $DepsCompose ps -q 2>$null
if ($depsIds) {
  Write-Host 'Stopping compose.dev-deps (host-Ruby stack)...'
  docker compose -f $DepsCompose down
}

if (-not (Test-Path $EnvFile)) {
  $bytes = New-Object byte[] 64
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $secret = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
  (Get-Content $EnvExample -Raw) -replace '(?m)^SECRET_KEY_BASE=.*$', "SECRET_KEY_BASE=$secret" |
    Set-Content -Path $EnvFile -NoNewline -Encoding utf8
  Write-Host 'Wrote .env from development.docker.env.example'
} else {
  Write-Host 'Keep existing .env'
  Write-Host 'For Docker mount mode ensure POSTGRES_HOST=postgres and REDIS_URL=redis://redis:6379'
}

Write-Host 'Using existing chatwoot:development image if present (skip rebuild; pass -Build to rebuild)...'
$doBuild = $false
if ($args -contains '-Build') { $doBuild = $true }
$img = docker images -q chatwoot:development
if (-not $img) { $doBuild = $true }

if ($doBuild) {
  Write-Host 'Building development image (first time may take a while)...'
  docker compose -f $ComposeFile build rails
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
  Write-Host "Found image $img — up --no-build"
}

Write-Host 'Starting stack...'
if ($doBuild) {
  docker compose -f $ComposeFile up -d
} else {
  docker compose -f $ComposeFile up -d --no-build
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'Stack is up.'
Write-Host 'First boot: wait until rails finishes bundle install, then:'
Write-Host '  docker compose -f deploy/compose.dev.yml exec rails bundle exec rails db:prepare'
Write-Host 'Optional seed:'
Write-Host '  docker compose -f deploy/compose.dev.yml exec rails bundle exec rails db:seed'
Write-Host 'App:     http://localhost:3001'
Write-Host 'Vite:    http://localhost:3036'
Write-Host 'Mailhog: http://localhost:8025'
Write-Host 'Logs:    docker compose -f deploy/compose.dev.yml logs -f rails'
