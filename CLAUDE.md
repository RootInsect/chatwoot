AGENTS.md

## Jingqi Fork — Git Remotes & Push

This checkout is an internal fork. Use these remotes:

| Remote | URL | Purpose |
|--------|-----|---------|
| `upstream` | `git@github.com:chatwoot/chatwoot.git` | Official Chatwoot (read / sync) |
| `origin` | `git@github.com:RootInsect/chatwoot.git` | GitHub fork (upstream sync only) |
| `codeup` | `git@codeup.aliyun.com:670498699d3c82efe37af916/jingqi/chatwoot.git` | **Internal company repo — push here** |

### Push rules

- **Company / feature branches** (`custom`, `custom-debrand`, and other internal work): push **only** to `codeup`, never to GitHub `origin`.
  ```bash
  git push -u codeup <branch>
  ```
- Do **not** push internal branches to `origin` or `upstream`.
- Prefer **SSH** for all remotes (HTTPS to GitHub is unreliable in this environment). If a large first push drops, retry with keepalive:
  ```bash
  GIT_SSH_COMMAND="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=120 -o TCPKeepAlive=yes" git push -u codeup <branch>
  ```
- Sync official updates via `upstream`/`origin` as needed; keep internal work on `codeup`-tracked branches.

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
