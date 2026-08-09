#!/usr/bin/env bash
# 本机构建 + 推送到私有仓（业务机禁止 docker build）。
#
# 固化顺序（重要）：
#   1) 代码已在对应分支（test / dev / custom）本地就绪
#   2) ./deploy/build-push.sh <test|dev|prod>     # build + push
#   3) git push codeup <branch>                   # 触发云效 → 业务机 pull + up
# 若先 push 再 build：镜像未就绪时流水线会失败，push 镜像后在云效「重新运行」即可。
#
# Usage:
#   ./deploy/build-push.sh test
#   ./deploy/build-push.sh dev
#   ./deploy/build-push.sh prod
#   REGISTRY_IMAGE=100.65.76.62:5000/jingqi/chatwoot ./deploy/build-push.sh test
#   ./deploy/build-push.sh test --cn          # 强制用 deploy/Dockerfile.cn
#   ./deploy/build-push.sh test --no-push     # 只 build 不推
#   ./deploy/build-push.sh test --dockerfile docker/Dockerfile
set -euo pipefail

ENV_NAME="${1:-}"
shift || true

NO_PUSH=0
DOCKERFILE=""
USE_CN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-push) NO_PUSH=1 ;;
    --cn) USE_CN=1 ;;
    --dockerfile)
      DOCKERFILE="${2:-}"
      shift
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
  shift
done

usage() {
  echo "Usage: $0 <test|dev|prod> [--cn] [--no-push] [--dockerfile PATH]" >&2
  exit 1
}

[[ -n "$ENV_NAME" ]] || usage

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

case "$ENV_NAME" in
  test)
    ALIAS_TAG=test-latest
    EXPECT_BRANCH=test
    PIPELINE_HINT="景齐-Chatwoot测试版 (5160619)"
    ;;
  dev)
    ALIAS_TAG=dev-latest
    EXPECT_BRANCH=dev
    PIPELINE_HINT="景齐-Chatwoot-dev版 (5158422)"
    ;;
  prod)
    ALIAS_TAG=prod-latest
    EXPECT_BRANCH=custom
    PIPELINE_HINT="景齐-Chatwoot正式版 (5158432)"
    ;;
  *)
    usage
    ;;
esac

REGISTRY_IMAGE="${REGISTRY_IMAGE:-100.65.76.62:5000/jingqi/chatwoot}"
SHA="$(git rev-parse --short HEAD)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$BRANCH" != "$EXPECT_BRANCH" ]]; then
  echo "WARN: current branch is '$BRANCH', expected '$EXPECT_BRANCH' for env=$ENV_NAME" >&2
  echo "      Continue only if this commit is what you intend to ship as ${ALIAS_TAG}." >&2
fi

if [[ -z "$DOCKERFILE" ]]; then
  if [[ -n "$USE_CN" && -f "$REPO_ROOT/deploy/Dockerfile.cn" ]]; then
    DOCKERFILE=deploy/Dockerfile.cn
  elif [[ -f "$REPO_ROOT/deploy/Dockerfile.cn" ]]; then
    # 国内默认走 CN Dockerfile（镜像源）；可用 --dockerfile docker/Dockerfile 覆盖
    DOCKERFILE=deploy/Dockerfile.cn
  else
    DOCKERFILE=docker/Dockerfile
  fi
fi

if [[ ! -f "$DOCKERFILE" ]]; then
  echo "Missing Dockerfile: $DOCKERFILE" >&2
  exit 1
fi

echo "==> Env       : $ENV_NAME"
echo "==> Branch    : $BRANCH (expect $EXPECT_BRANCH)"
echo "==> Commit    : $SHA"
echo "==> Dockerfile: $DOCKERFILE"
echo "==> Image     : ${REGISTRY_IMAGE}:${SHA} + ${ALIAS_TAG}"

docker build -f "$DOCKERFILE" \
  -t "${REGISTRY_IMAGE}:${SHA}" \
  -t "${REGISTRY_IMAGE}:${ALIAS_TAG}" \
  .

if [[ "$NO_PUSH" -eq 1 ]]; then
  echo "==> Skip push (--no-push)"
else
  echo "==> Pushing..."
  docker push "${REGISTRY_IMAGE}:${SHA}"
  docker push "${REGISTRY_IMAGE}:${ALIAS_TAG}"
fi

echo
echo "Done. Next:"
echo "  git push codeup ${EXPECT_BRANCH}"
echo "  → 云效 ${PIPELINE_HINT} 会在业务机 pull ${ALIAS_TAG} 并 up"
echo "  若分支已推过：在云效对该流水线点「运行」即可"
