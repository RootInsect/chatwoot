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
| **正式版（对外线上）** | `custom` | `prod` | 对外提供服务的唯一线上基线；只从 `dev` 晋升，禁止任务分支直推 |
| **内部可发布版** | `dev` | `staging` | 内部最新、已决定可发布候选；合并进 `dev` 后自动部署 staging |
| **单任务测试版** | `task/<name>` / `feat/<name>` / `custom-*` | `preview-*` | AI 每完成一个任务推送后自动部署，供内部测；通过后再合入 `dev` |

```
task/*  ──(测试通过 + MR)──►  dev  ──(人工确认发布)──►  custom
                              │                         │
                         staging 自动部署              prod 审批部署
```

### Push rules

- Push **only** to `codeup`, never to GitHub `origin` / `upstream` for internal work.
  ```bash
  git push -u codeup <branch>
  ```
- AI / 单任务：一律在 `task/<任务名>`（或等价前缀）开发并推送，**不要**直接推 `dev` 或 `custom`。
- 合入顺序：`task/*` → `dev` → `custom`。
- Prefer **SSH** (HTTPS to GitHub is unreliable here). Large first push keepalive:
  ```bash
  GIT_SSH_COMMAND="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=120 -o TCPKeepAlive=yes" git push -u codeup <branch>
  ```

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
