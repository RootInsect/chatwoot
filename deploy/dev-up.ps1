# Start local Postgres + Redis for Chatwoot development (hot reload on host).
# Usage: .\deploy\dev-up.ps1

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $Root

$ComposeFile = Join-Path $Root 'deploy\compose.dev-deps.yml'
$EnvExample = Join-Path $Root 'deploy\env\development.env.example'
$EnvFile = Join-Path $Root '.env'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw 'Need Docker Desktop installed and running.'
}

docker compose -f $ComposeFile up -d
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not (Test-Path $EnvFile)) {
  $bytes = New-Object byte[] 64
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $secret = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
  (Get-Content $EnvExample -Raw) -replace '(?m)^SECRET_KEY_BASE=.*$', "SECRET_KEY_BASE=$secret" |
    Set-Content -Path $EnvFile -NoNewline -Encoding utf8
  Write-Host "Wrote .env from development.env.example (generated SECRET_KEY_BASE)"
} else {
  Write-Host 'Keep existing .env'
  Write-Host 'Ensure POSTGRES_PORT=55432 and REDIS_URL=redis://localhost:56379 match compose.dev-deps.yml'
}

Write-Host ''
Write-Host 'Deps are up (postgres :55432, redis :56379).'
Write-Host 'First time: prefer WSL2/Linux for Ruby, then run ./deploy/dev-setup.sh'
Write-Host 'Or on a machine with Ruby 3.4.4 + Node 24 + pnpm:'
Write-Host '  bundle install; pnpm install; bundle exec rails db:prepare; pnpm dev'
Write-Host 'App: http://localhost:3001'
