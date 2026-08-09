#!/usr/bin/env bash
# 开发机首次 / 依赖更新后：装 gem/node、准备数据库
# 前置：Ruby(.ruby-version) + Node 24 + pnpm + Docker
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${RBENV_SHELL:-}" ]] && command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

echo "==> Start Postgres/Redis"
"$ROOT/deploy/dev-up.sh"

echo "==> Ruby $(cat .ruby-version 2>/dev/null || echo '?')"
command -v ruby >/dev/null || { echo "Install Ruby $(cat .ruby-version) via rbenv" >&2; exit 1; }
command -v bundle >/dev/null || gem install bundler -v 2.5.16

echo "==> bundle install"
bundle check || bundle install

echo "==> pnpm install (Node 24.x)"
command -v pnpm >/dev/null || { echo "Install pnpm (corepack enable && corepack prepare pnpm@latest --activate)" >&2; exit 1; }
pnpm install

echo "==> db:prepare"
bundle exec rails db:prepare

echo
echo "Ready. Start hot-reload stack:"
echo "  pnpm dev"
echo "  # or: overmind start -f Procfile.dev"
echo "Open http://localhost:3001"
echo
echo "Do NOT use ./deploy/build-push.sh for day-to-day coding."
echo "Use build-push only when promoting to test/dev/custom."
