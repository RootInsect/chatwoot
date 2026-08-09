# Start Chatwoot full-stack local Docker (bind-mount source for hot reload).
# Usage: ./deploy/dev-docker-up.sh
# No local Ruby required.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMPOSE_FILE="$ROOT/deploy/compose.dev.yml"
DEPS_COMPOSE="$ROOT/deploy/compose.dev-deps.yml"
ENV_EXAMPLE="$ROOT/deploy/env/development.docker.env.example"
ENV_FILE="$ROOT/.env"

if ! command -v docker >/dev/null 2>&1; then
  echo "Need Docker installed and running." >&2
  exit 1
fi

# Avoid two local DB stacks at once
if docker compose -f "$DEPS_COMPOSE" ps -q 2>/dev/null | grep -q .; then
  echo "Stopping compose.dev-deps (host-Ruby stack)…"
  docker compose -f "$DEPS_COMPOSE" down
fi

if [[ ! -f "$ENV_FILE" ]]; then
  secret="$(openssl rand -hex 64 2>/dev/null || head -c 64 /dev/urandom | xxd -p -c 256)"
  sed "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=${secret}/" "$ENV_EXAMPLE" >"$ENV_FILE"
  echo "Wrote .env from development.docker.env.example"
else
  echo "Keep existing .env"
  echo "For Docker mount mode ensure POSTGRES_HOST=postgres and REDIS_URL=redis://redis:6379"
fi

echo "Building development image (first time may take a while)…"
docker compose -f "$COMPOSE_FILE" build rails

echo "Starting stack…"
docker compose -f "$COMPOSE_FILE" up -d

echo
echo "Stack is up."
echo "First boot: wait until rails finishes bundle install, then:"
echo "  docker compose -f deploy/compose.dev.yml exec rails bundle exec rails db:prepare"
echo "Optional seed:"
echo "  docker compose -f deploy/compose.dev.yml exec rails bundle exec rails db:seed"
echo "App:     http://localhost:3001"
echo "Vite:    http://localhost:3036"
echo "Mailhog: http://localhost:8025"
echo "Logs:    docker compose -f deploy/compose.dev.yml logs -f rails"
