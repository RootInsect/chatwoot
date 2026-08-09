# 本地 / 开发机环境（热更新）

和 `test` / `dev` / `prod` **镜像发布链路分开**：日常改功能走这里，不要每次 `build-push`。

```
开发机（推荐）：Docker 全栈 + 源码挂载
                rails / sidekiq / vite + Postgres + Redis
                      ↓ 热更新，本机无需 Ruby

备选：Docker 只跑 DB，本机 pnpm dev（需 Ruby 3.4.4 + Node 24）

要共享 / 贴近线上：再 MR → test → build-push（约数分钟）
```

## 推荐：Docker 源码挂载（Windows 默认）

本机只需 **Docker Desktop**。代码挂进容器，改文件即热更新。

```powershell
.\deploy\dev-docker-up.ps1
# 首次构建可能较久（15–40 分钟）；有缓存后会快很多

# 等 rails 日志出现监听端口后：
docker compose -f deploy/compose.dev.yml exec rails bundle exec rails db:prepare
# 可选：
docker compose -f deploy/compose.dev.yml exec rails bundle exec rails db:seed
```

```bash
# Linux / macOS / WSL
chmod +x deploy/dev-docker-up.sh
./deploy/dev-docker-up.sh
docker compose -f deploy/compose.dev.yml exec rails bundle exec rails db:prepare
```

| 地址 | 说明 |
|------|------|
| http://localhost:3001 | 应用（宿主机；容器内仍为 3000） |
| http://localhost:3036 | Vite |
| http://localhost:8025 | Mailhog |

`.env` 使用 Docker 服务名：见 [`env/development.docker.env.example`](env/development.docker.env.example)  
（`POSTGRES_HOST=postgres`，`REDIS_URL=redis://redis:6379`）。

### 日常命令

| 目的 | 命令 |
|------|------|
| 起/停 | `.\deploy\dev-docker-up.ps1` / `docker compose -f deploy/compose.dev.yml down` |
| 日志 | `docker compose -f deploy/compose.dev.yml logs -f rails` |
| 控制台 | `docker compose -f deploy/compose.dev.yml exec rails bundle exec rails c` |
| 重建镜像 | `docker compose -f deploy/compose.dev.yml build rails` |

Postgres / Redis **不映射本机端口**，不与本机 `6379` 冲突。

与 [`compose.dev-deps.yml`](compose.dev-deps.yml) **二选一**；`dev-docker-up` 会自动停掉 deps 栈。

---

## 备选：本机跑 Rails（需 Ruby）

Docker 只起 Postgres + Redis，应用在宿主机 `pnpm dev`。

| 工具 | 版本 |
|------|------|
| Docker | 能跑 compose |
| Ruby | `.ruby-version`（当前 3.4.4），推荐 mise / rbenv / WSL2 |
| Node | 24.x（可用 nvm） |
| pnpm | `packageManager` 字段版本 |

```powershell
.\deploy\dev-up.ps1
.\deploy\dev-setup.ps1   # 需已装 Ruby/Node
pnpm dev
```

```bash
./deploy/dev-setup.sh
pnpm dev
```

此时 `.env` 用 [`env/development.env.example`](env/development.env.example)  
（`POSTGRES_HOST=localhost`，端口 `55432` / `56379`）。

---

## 和发布环境的关系

| | 开发机 | test / dev / prod |
|--|--------|-------------------|
| 代码 | 挂载或本机热更新 | 打进镜像 |
| DB/Redis | `compose.dev` 或 `compose.dev-deps` | 各环境独立 compose |
| 发布 | 不需要 | `build-push` → 云效 pull |

禁止：在开发机上为了「快」去改业务机挂载源码目录；正式/测试仍走镜像。

踩坑与性能说明（Windows 挂载慢、Vite、CRLF 等）见 [`LESSONS.md`](LESSONS.md)。
