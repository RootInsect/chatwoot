#!/usr/bin/env bash
# 在目标机上从仓库模板初始化一套环境目录（不覆盖已有 .env）。
# Usage:
#   ./deploy/bootstrap-env.sh prod /opt/1panel/apps/chatwoot/chatwoot-prod
#   ./deploy/bootstrap-env.sh dev  /opt/1panel/apps/chatwoot/chatwoot-dev
#   ./deploy/bootstrap-env.sh test /opt/1panel/apps/chatwoot/chatwoot-test
set -euo pipefail

ENV_NAME="${1:-}"
TARGET="${2:-}"

usage() {
  echo "Usage: $0 <prod|dev|test> <target-dir>" >&2
  echo "  (legacy alias: staging → dev)" >&2
  exit 1
}

[[ -n "$ENV_NAME" && -n "$TARGET" ]] || usage

case "$ENV_NAME" in
  prod) TEMPLATE_NAME=chatwoot-prod.env.example ;;
  dev|staging) TEMPLATE_NAME=chatwoot-dev.env.example ;;
  test) TEMPLATE_NAME=chatwoot-test.env.example ;;
  *) usage ;;
esac

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$ROOT/env/$TEMPLATE_NAME"
COMPOSE="$ROOT/compose.yml"

[[ -f "$TEMPLATE" ]] || { echo "Missing $TEMPLATE" >&2; exit 1; }
[[ -f "$COMPOSE" ]] || { echo "Missing $COMPOSE" >&2; exit 1; }

mkdir -p "$TARGET"
cp -n "$COMPOSE" "$TARGET/compose.yml" 2>/dev/null || cp "$COMPOSE" "$TARGET/compose.yml"

if [[ -f "$TARGET/.env" ]]; then
  echo "Keep existing $TARGET/.env (not overwritten)"
else
  SECRET="$(openssl rand -hex 64)"
  PG_PASS="$(openssl rand -hex 24)"
  REDIS_PASS="$(openssl rand -hex 24)"
  sed \
    -e "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=${SECRET}|" \
    -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${PG_PASS}|" \
    -e "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASS}|" \
    -e "s|^REDIS_URL=.*|REDIS_URL=redis://:${REDIS_PASS}@redis:6379|" \
    "$TEMPLATE" >"$TARGET/.env"
  echo "Wrote $TARGET/.env (generated SECRET/POSTGRES/REDIS; fill SMTP_* manually)"
fi

echo "Done. Next:"
echo "  1) Edit SMTP_USERNAME / SMTP_PASSWORD / MAILER_SENDER_EMAIL in $TARGET/.env"
echo "  2) docker login <registry> && cd $TARGET && docker compose pull && docker compose up -d"
echo "  3) docker compose exec -T rails bundle exec rails db:chatwoot_prepare"
