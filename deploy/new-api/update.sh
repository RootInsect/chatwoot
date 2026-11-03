#!/usr/bin/env bash
# 在业务机 NewAPI 部署目录执行：拉取最新镜像并滚动重启（保留 PgSQL 数据卷）
# 用法：
#   cd /opt/1panel/apps/new-api && bash update.sh
# 或从仓库：
#   bash deploy/new-api/update.sh /opt/1panel/apps/new-api

set -euo pipefail

DEPLOY_DIR="${1:-.}"
cd "$DEPLOY_DIR"

if [[ ! -f compose.yml && ! -f docker-compose.yml ]]; then
  echo "No compose.yml in $PWD" >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Missing .env in $PWD" >&2
  exit 1
fi

# 确认走 PostgreSQL，避免误用 SQLite
if ! grep -qE '^POSTGRES_PASSWORD=.+' .env; then
  echo "POSTGRES_PASSWORD missing in .env — NewAPI must use PostgreSQL" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d%H%M%S)"
BACKUP_DIR="./backups/${STAMP}"
mkdir -p "$BACKUP_DIR"
cp -a .env "$BACKUP_DIR/"
cp -a compose.yml "$BACKUP_DIR/" 2>/dev/null || cp -a docker-compose.yml "$BACKUP_DIR/" 2>/dev/null || true

echo "==> Backup env/compose -> $BACKUP_DIR"

# 若仍挂着旧 SQLite 数据文件，一并备份（迁库前保险）
if [[ -f ./data/one-api.db ]]; then
  cp -a ./data/one-api.db "$BACKUP_DIR/one-api.db"
  echo "==> Backed up ./data/one-api.db"
fi

# 在线 pg_dump（容器已起时）
if docker compose ps --status running 2>/dev/null | grep -q postgres; then
  echo "==> pg_dump new-api database"
  docker compose exec -T postgres \
    sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
    >"$BACKUP_DIR/new-api.sql" || echo "warn: pg_dump failed (may be first boot)" >&2
fi

echo "==> Pull latest image"
docker compose pull

echo "==> Recreate containers"
docker compose up -d

echo "==> Status"
docker compose ps
docker compose logs --tail=80 new-api || true

echo "Done. Verify admin UI and /api/status."
