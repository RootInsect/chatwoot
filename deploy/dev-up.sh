#!/usr/bin/env bash
# 启动本地开发依赖（Postgres + Redis）并确保根目录有 .env
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMPOSE_FILE="$ROOT/deploy/compose.dev-deps.yml"
ENV_EXAMPLE="$ROOT/deploy/env/development.env.example"

if ! command -v docker >/dev/null 2>&1; then
  echo "Need docker installed and running." >&2
  exit 1
fi

docker compose -f "$COMPOSE_FILE" up -d

if [[ ! -f "$ROOT/.env" ]]; then
  if command -v openssl >/dev/null 2>&1; then
    SECRET="$(openssl rand -hex 64)"
  else
    SECRET="$(head -c 64 /dev/urandom | xxd -p -c 64 | tr -d '\n')"
  fi
  sed "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=${SECRET}|" "$ENV_EXAMPLE" >"$ROOT/.env"
  echo "Wrote .env from development.env.example (generated SECRET_KEY_BASE)"
else
  echo "Keep existing .env"
  echo "Ensure POSTGRES_PORT=55432 and REDIS_URL=redis://localhost:56379 match compose.dev-deps.yml"
fi

echo
echo "Deps are up (postgres :55432, redis :56379)."
echo "First time on this machine: ./deploy/dev-setup.sh"
echo "Then: pnpm dev   # or: overmind start -f Procfile.dev"
echo "App:  http://localhost:3001"
