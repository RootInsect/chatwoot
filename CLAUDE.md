AGENTS.md

## Jingqi Fork — Git Remotes & Push

This checkout is an internal fork. Use these remotes:

| Remote | URL | Purpose |
|--------|-----|---------|
| `upstream` | `git@github.com:chatwoot/chatwoot.git` | Official Chatwoot (read / sync) |
| `origin` | `git@github.com:RootInsect/chatwoot.git` | GitHub fork (upstream sync only) |
| `codeup` | `git@codeup.aliyun.com:670498699d3c82efe37af916/jingqi/chatwoot.git` | **Internal company repo — push here** |

### Branch model (source of truth)

| 层级 | 分支 | 环境 | 说明 |
|------|------|------|------|
| **正式版（对外线上）** | `custom` | `prod` | 对外唯一线上基线；只从 `dev` 晋升，禁止任务分支直推 |
| **内部可发布版（dev）** | `dev` | `dev` | 相对稳定的联调 / 准发布候选；合入后自动部署 |
| **测试版（随时覆盖）** | `test` | `test` | 试验场，可频繁覆盖；任务合入或推送后自动部署 |
| **单任务开发** | `task/<name>` 等 | （无独立环境） | 只在分支上开发；测完合入 `test`，不要直推 `dev`/`custom` |

```
task/* ──(MR)──► test ──(认可)──► dev ──(确认发布)──► custom
                  │                 │                    │
              test 自动部署      dev 自动部署         prod 审批部署
              （随时覆盖）       （准发布）
```

### Push rules

- Push **only** to `codeup`, never to GitHub `origin` / `upstream` for internal work.
  ```bash
  git push -u codeup <branch>
  ```
- AI / 单任务：一律在 `task/<任务名>`（或等价前缀）开发并推送，**不要**直接推 `test` / `dev` / `custom`（合入用 MR；`test` 仅在约定允许时可由负责人直接推）。
- 合入顺序：`task/*` → `test` → `dev` → `custom`。
- Prefer **SSH** (HTTPS to GitHub is unreliable here). Large first push keepalive:
  ```bash
  GIT_SSH_COMMAND="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=120 -o TCPKeepAlive=yes" git push -u codeup <branch>
  ```

### Deploy automation

See [`deploy/README.md`](deploy/README.md) for the full playbook (私有仓 / ACR + Docker Compose + 云效).

**固化链路（禁止业务机 docker build）**：

1. 本机：`./deploy/build-push.sh test|dev|prod`（或 `.\deploy\build-push.ps1 …`）→ 推 `*-latest` + `$SHA` 到私有仓。
2. `git push codeup` 对应分支 → 云效流水线在业务机 `compose pull && up`。
3. 顺序：先 build-push，再 git push（或 push 后云效重跑）。

其它：

1. 目录：`/opt/1panel/apps/chatwoot/chatwoot-{prod,test}/`；现网 `dev` 可能仍为 `chatwoot-staging`。
2. 晋升：MR `test` → `dev` → `custom`（正式版审批）。
3. 不做 per-task preview；一套 `test` 栈随时覆盖即可。

## Jingqi Fork — Billing & Access

- Self-serve Stripe subscription / checkout / credit top-up is **disabled**.
- Users are directed to **contact support**; features and limits are granted manually in **Super Admin → Accounts → Edit** (`enabled_features`, `limits`, optional `custom_attributes.plan_name` + reconcile).
- Do not re-enable Stripe customer creation without an explicit product decision.

## Jingqi Fork — Contact Support

- Configure under **Super Admin → Settings → Contact Support** (`/super_admin/app_config?config=support`).
- Preferred (same-system widget):
  1. Create a support Account + Website inbox on this installation.
  2. Set `CHATWOOT_SUPPORT_WEBSITE_TOKEN` to that inbox website token.
  3. Leave `CHATWOOT_SUPPORT_SCRIPT_URL` blank to use this installation `FRONTEND_URL`.
- Fallback: set `SUPPORT_CONTACT_URL` (`mailto:`, `https://`, or an in-app path).
- Dashboard / billing / paywall “Contact support” uses the widget when loaded, otherwise opens the fallback URL.
- Chatwoot Hub no longer overwrites local support widget tokens.
