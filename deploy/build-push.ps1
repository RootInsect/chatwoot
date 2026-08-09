# Local build + push to private registry. Do NOT docker build on the app host.
#
# Order:
#   1) checkout target branch
#   2) .\deploy\build-push.ps1 test|dev|prod
#   3) git push codeup <branch>
#
# Usage:
#   .\deploy\build-push.ps1 test
#   .\deploy\build-push.ps1 test -NoPush
#   .\deploy\build-push.ps1 test -Dockerfile docker/Dockerfile
#   $env:REGISTRY_IMAGE='100.65.76.62:5000/jingqi/chatwoot'; .\deploy\build-push.ps1 test

param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('test', 'dev', 'prod')]
  [string]$EnvName,

  [switch]$NoPush,

  [string]$Dockerfile = '',

  [string]$RegistryImage = $(if ($env:REGISTRY_IMAGE) { $env:REGISTRY_IMAGE } else { '100.65.76.62:5000/jingqi/chatwoot' })
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $RepoRoot

switch ($EnvName) {
  'test' {
    $AliasTag = 'test-latest'
    $ExpectBranch = 'test'
    $PipelineHint = 'Chatwoot-test pipeline 5160619'
  }
  'dev' {
    $AliasTag = 'dev-latest'
    $ExpectBranch = 'dev'
    $PipelineHint = 'Chatwoot-dev pipeline 5158422'
  }
  'prod' {
    $AliasTag = 'prod-latest'
    $ExpectBranch = 'custom'
    $PipelineHint = 'Chatwoot-prod pipeline 5158432'
  }
}

$Sha = (git rev-parse --short HEAD).Trim()
$Branch = (git rev-parse --abbrev-ref HEAD).Trim()

if ($Branch -ne $ExpectBranch) {
  Write-Warning "current branch is '$Branch', expected '$ExpectBranch' for env=$EnvName"
}

if (-not $Dockerfile) {
  $Cn = Join-Path $RepoRoot 'deploy\Dockerfile.cn'
  if (Test-Path $Cn) {
    $Dockerfile = 'deploy/Dockerfile.cn'
  } else {
    $Dockerfile = 'docker/Dockerfile'
  }
}

if (-not (Test-Path (Join-Path $RepoRoot $Dockerfile))) {
  throw "Missing Dockerfile: $Dockerfile"
}

Write-Host "==> Env       : $EnvName"
Write-Host "==> Branch    : $Branch (expect $ExpectBranch)"
Write-Host "==> Commit    : $Sha"
Write-Host "==> Dockerfile: $Dockerfile"
Write-Host "==> Image     : ${RegistryImage}:${Sha} + ${AliasTag}"

$Entrypoint = Join-Path $RepoRoot 'docker\entrypoints\rails.sh'
if (Test-Path $Entrypoint) {
  $bytes = [System.IO.File]::ReadAllBytes($Entrypoint)
  $hasCr = $false
  foreach ($b in $bytes) {
    if ($b -eq 13) { $hasCr = $true; break }
  }
  if ($hasCr) {
    Write-Warning "docker/entrypoints/rails.sh has CRLF. Dockerfile will strip \\r; prefer git attributes eol=lf."
  }
}

docker build -f $Dockerfile `
  -t "${RegistryImage}:${Sha}" `
  -t "${RegistryImage}:${AliasTag}" `
  .

if ($NoPush) {
  Write-Host '==> Skip push (-NoPush)'
} else {
  Write-Host '==> Pushing...'
  docker push "${RegistryImage}:${Sha}"
  docker push "${RegistryImage}:${AliasTag}"
}

Write-Host ''
Write-Host 'Done. Next:'
Write-Host "  git push codeup $ExpectBranch"
Write-Host "  -> Yunxiao $PipelineHint will pull $AliasTag on the host"
Write-Host '  If branch already pushed: re-run the pipeline in Yunxiao UI'
