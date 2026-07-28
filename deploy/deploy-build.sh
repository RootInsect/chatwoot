#!/usr/bin/env bash
# [LEGACY / 排障] 业务机本地 build + 部署。正常路径请用本机：
#   ./deploy/build-push.sh test|dev|prod   → 云效流水线 pull
# 勿在业务机常态执行本脚本（占满 CPU）。
# Usage (on host, emergency only):
#   ENV=prod BRANCH=custom ./deploy-build.sh [--migrate]
#   ENV=dev  BRANCH=dev    ./deploy-build.sh [--migrate]
#   ENV=test BRANCH=test   ./deploy-build.sh [--migrate]
#
# Layout:
#   /opt/1panel/apps/chatwoot/src
#   /opt/1panel/apps/chatwoot/chatwoot-prod
#   /opt/1panel/apps/chatwoot/chatwoot-dev      # or legacy chatwoot-staging
#   /opt/1panel/apps/chatwoot/chatwoot-test

set -euo pipefail

ENV_NAME="${ENV:-dev}"
BRANCH="${BRANCH:-dev}"
ROOT="/opt/1panel/apps/chatwoot"
SRC="$ROOT/src"
MIGRATE=0
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -i /root/.ssh/id_ed25519_1panel -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new}"

if [[ "${1:-}" == "--migrate" ]]; then
  MIGRATE=1
fi

case "$ENV_NAME" in
  prod)
    DEPLOY_DIR="$ROOT/chatwoot-prod"
    IMAGE_TAG_ALIAS="prod-latest"
    ;;
  dev|staging)
    if [[ -d "$ROOT/chatwoot-dev" ]]; then
      DEPLOY_DIR="$ROOT/chatwoot-dev"
    else
      DEPLOY_DIR="$ROOT/chatwoot-staging"
    fi
    IMAGE_TAG_ALIAS="dev-latest"
    ;;
  test)
    DEPLOY_DIR="$ROOT/chatwoot-test"
    IMAGE_TAG_ALIAS="test-latest"
    ;;
  *)
    echo "ENV must be prod, dev, or test" >&2
    exit 1
    ;;
esac

if [[ ! -f "$DEPLOY_DIR/.env" ]]; then
  echo "Missing $DEPLOY_DIR/.env" >&2
  exit 1
fi

if [[ ! -d "$SRC/.git" ]]; then
  echo "Missing git repo at $SRC — clone first" >&2
  exit 1
fi

echo "==> Updating source ($BRANCH)"
cd "$SRC"
rm -f .git/index.lock
git fetch origin "refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}" --depth=1
git checkout -B "$BRANCH" "origin/${BRANCH}"
git reset --hard "origin/${BRANCH}"

SHA="$(git rev-parse --short HEAD)"
IMAGE="jingqi/chatwoot"

# Prefer CN mirror Dockerfile (Alpine / RubyGems / npm) when present
DOCKERFILE="$ROOT/Dockerfile.cn"
if [[ ! -f "$DOCKERFILE" ]]; then
  DOCKERFILE="$SRC/deploy/Dockerfile.cn"
fi
if [[ ! -f "$DOCKERFILE" ]]; then
  DOCKERFILE="$SRC/docker/Dockerfile"
fi

echo "==> Building ${IMAGE}:${SHA} (${IMAGE_TAG_ALIAS}) with $DOCKERFILE"
docker build -f "$DOCKERFILE" \
  -t "${IMAGE}:${SHA}" \
  -t "${IMAGE}:${IMAGE_TAG_ALIAS}" \
  .

# Point compose at the built tag without rewriting secrets
if grep -q '^IMAGE_TAG=' "$DEPLOY_DIR/.env"; then
  sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=${SHA}/" "$DEPLOY_DIR/.env"
else
  echo "IMAGE_TAG=${SHA}" >> "$DEPLOY_DIR/.env"
fi
if grep -q '^IMAGE=' "$DEPLOY_DIR/.env"; then
  sed -i "s|^IMAGE=.*|IMAGE=${IMAGE}|" "$DEPLOY_DIR/.env"
else
  echo "IMAGE=${IMAGE}" >> "$DEPLOY_DIR/.env"
fi

echo "==> Starting stack in $DEPLOY_DIR"
cd "$DEPLOY_DIR"
docker compose up -d

if [[ "$MIGRATE" -eq 1 ]]; then
  echo "==> db:chatwoot_prepare"
  docker compose exec -T rails bundle exec rails db:chatwoot_prepare
fi

echo "==> Done (${ENV_NAME} @ ${SHA})"
docker compose ps
