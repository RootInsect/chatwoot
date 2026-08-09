#!/usr/bin/env bash
# Run on the target host inside the env directory (next to compose.yml + .env).
# Usage:
#   IMAGE_TAG=dev-latest ./deploy.sh
#   IMAGE_TAG=abc1234 ./deploy.sh --migrate

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env in $ROOT_DIR" >&2
  exit 1
fi

# shellcheck disable=SC1091
set -a
source .env
set +a

: "${IMAGE:?Set IMAGE in .env (ACR repo)}"
: "${IMAGE_TAG:?Set IMAGE_TAG (e.g. dev-latest or commit sha)}"

echo "==> Pulling ${IMAGE}:${IMAGE_TAG}"
docker compose -f compose.yml pull

echo "==> Starting stack"
docker compose -f compose.yml up -d

if [[ "${1:-}" == "--migrate" ]]; then
  echo "==> Running db:chatwoot_prepare"
  docker compose -f compose.yml exec -T rails bundle exec rails db:chatwoot_prepare
fi

echo "==> Done"
docker compose -f compose.yml ps
