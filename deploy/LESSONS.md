# Jingqi Chatwoot — 环境与流水线经验备忘

> 实践沉淀（2026-07）。操作手册仍以 [`README.md`](README.md)、[`DEV.md`](DEV.md) 为准；本文记 **踩坑、取舍、固化约定**。

---

## 1. 四套「环境」分别干什么

| 名称 | 分支 | 镜像 / 形态 | 宿主机端口（现网） | 用途 |
|------|------|-------------|-------------------|------|
| **本地开发** | 任意 `task/*` | 不发版；`compose.dev.yml` 源码挂载 | **3001**（避开本机 3000） | 日常改代码、热更新 |
| **test** | `test` | `test-latest` | **3004** | 试验场，随时覆盖 |
| **dev（准发布）** | `dev` | `dev-latest` | **3002**（目录或仍叫 `chatwoot-staging`） | 内部认可后再晋升 |
| **prod（正式）** | `custom` | `prod-latest` | **3000** | 对外线上，人工确认后部署 |

```
本地热更新 ──MR──► test ──认可──► dev ──审批──► custom(prod)
                  试验           准发布         正式
```

**不要混淆：**

- 「本地开发」≠「dev 分支环境」。本地不走云效；`dev` 是准发布栈。
- 不做 per-task preview 栈；任务在 `task/*` 开发，验证靠覆盖更新唯一的 `test`。

---

## 2. Git 远程与推送纪律

| Remote | 用途 |
|--------|------|
| `upstream` | 官方 Chatwoot（只读 / 同步） |
| `origin` | GitHub fork（上游同步用） |
| **`codeup`** | **公司内网仓 —— 日常只推这里** |

- 内部功能 / 部署相关改动：**只 `git push codeup <branch>`**，不要推 GitHub。
- 本机访问 GitHub HTTPS 常不稳定；优先 **SSH**。大包首次推送可加 keepalive：
  ```bash
  GIT_SSH_COMMAND="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=120 -o TCPKeepAlive=yes" git push -u codeup <branch>
  ```

---

## 3. 发布链路（已固化）

### 正确路径

```
本机 build-push (test|dev|prod)
        │
        ▼
私有仓 100.65.76.62:5000/jingqi/chatwoot:*-latest (+ $SHA)
        │
git push codeup 对应分支 ──► 云效 webhook
        │
        ▼
业务机：compose pull && up（+ migrate）
```

### 铁律

1. **业务机禁止 `docker build`**。曾在服务器上 build，CPU 打满拖垮整机。
2. **顺序：先 `build-push`，再 `git push`**（或 push 后重跑流水线）。否则流水线 pull 到旧 tag。
3. 流水线只做 **pull + 重启**，YAML 见 `yunxiao-pipeline-{test,dev,prod}.yaml`。
4. 冷构建约 15–40 分钟；有缓存约 4–6 分钟。**日常改功能不要每次 build-push**，用本地开发机。

### 私有仓

- 地址：`100.65.76.62:5000`（与业务机同机时注意磁盘/负载；长期可迁 ACR）。
- Docker Desktop 需配 **insecure-registries**。
- 国内构建优先：`deploy/Dockerfile.cn` / `build-push` 默认走国内源。

### 迁移注意

- 容器刚起来时慎用 `docker compose exec rails …`（可能还在启动）；可用 `compose run --rm rails …`。
- 各环境 **独立** Postgres/Redis，不要共用数据卷。

---

## 4. 流水线 / 分支对应（速查）

| 环境 | 分支 | Tag | 目录习惯 | 云效流水线（名称备忘） |
|------|------|-----|----------|------------------------|
| test | `test` | `test-latest` | `chatwoot-test` | 景齐-Chatwoot测试版 |
| dev | `dev` | `dev-latest` | `chatwoot-dev` 或现网 `chatwoot-staging` | 景齐-Chatwoot-dev版 |
| prod | `custom` | `prod-latest` | `chatwoot-prod` | 景齐-Chatwoot正式版 |

合入顺序：`task/*` → `test` → `dev` → `custom`。

### 4.1 定时同步官方（upstream）

规则：[`CLAUDE.md`](../CLAUDE.md)「Upstream sync」；**游标文件**：[`upstream-sync-cursor.md`](upstream-sync-cursor.md)。

- **只判断** `cursor..upstream/develop` 的新增提交，不对整仓代码做主观分类。
- **功能相关** → MR 合入 `test` → 再审核晋升；审完推进游标。
- **中途舍弃 / 平台内部本轮不做** → 记下舍弃提交，游标停在其前；**下次从舍弃那条再判**。
- 游标变更要提交进仓库，避免下次不知道从哪接着看。

---

## 5. 本地开发：方案与坑

### 5.1 推荐：`deploy/compose.dev.yml`（全容器 + 源码挂载）

- 本机只需 Docker，不必装 Ruby。
- 脚本：`.\deploy\dev-docker-up.ps1` / `./deploy/dev-docker-up.sh`
- 应用：**http://localhost:3001**（本机 3000 常被其它服务占用，例如 new-api）
- Vite：3036；Mailhog：8025
- Postgres/Redis：**不映射到宿主机**，避免和本机 6379/5432 冲突
- `.env` 用 Docker 服务名：见 `env/development.docker.env.example`  
  （`POSTGRES_HOST=postgres`，`REDIS_URL=redis://redis:6379`，`REDIS_PASSWORD=` 空，`POSTGRES_PASSWORD=postgres`）

与 `compose.dev-deps`（只起 DB、本机跑 Rails）**二选一**；`dev-docker-up` 会先停 deps。

### 5.2 踩过的坑 → 对策

| 问题 | 现象 | 对策 |
|------|------|------|
| Windows **CRLF** | Alpine `rails.sh` / `bin/vite`：`no such file` / `can't execute 'ruby\r'` | Dockerfile 里 `sed` 剥 `\r`；compose entrypoint 启动前再剥一层；`.gitattributes` 强制 `*.sh` LF |
| **空 `POSTGRES_PASSWORD`** | Postgres 容器重启：`password is not specified` | 开发栈固定 `postgres` / `postgres` |
| Redis 有密码 vs 无密码 | 连不上 Redis | 开发 compose 无密码；`.env` 里 `REDIS_PASSWORD=` 必须空 |
| 官方根目录 `docker-compose` 与开发栈并存 | 占 6379/5432/3001，两套 DB | 只留 `chatwoot-dev`；`docker compose down` 并删旧 volume |
| 构建时 **GitHub git gems 超时** | `bundle install` clone `devise-secure_password` 失败 | 优先复用已有 `chatwoot:development`（`up --no-build`）；脚本默认有镜像则跳过 build；`-Build` 才重建；或用 `Dockerfile.cn` + 网络畅通时构建 |
| 空卷挂到 **`/gems`** | 盖住镜像预装 gems，全量重装且易再撞 GitHub | **不要**把空 named volume 挂到 `/gems` |
| Vite 只听 `localhost` | Rails→Vite `Connection refused`，页面卡住 | `config/vite.json` 设 `host: 0.0.0.0`；`vite.config.ts` 设 `server.allowedHosts: true` |
| Rails 找不到 Vite | 日志 `Building with Vite` 本机编译极慢 / 超时 | Rails 环境变量 **`VITE_RUBY_HOST=vite`**、`VITE_RUBY_PORT=3036`（不是自定义的 `VITE_DEV_SERVER_HOST`） |
| Vite 每次 `pnpm install --force` | 重启再下 5+ 分钟 | 开发 compose 自定义 entrypoint：有 `node_modules/vite` 则跳过 |
| PowerShell 脚本 Unicode `…` | `TerminatorExpectedAtEndOfString` | `dev-docker-up.ps1` 用 ASCII `...` |
| **访问很慢** | 见下方 **§5.2.1**（已坐实，不必再查） | 根因固定：Windows bind mount + Vite 海量小文件 |

### 5.2.1 本地「请求都很慢」——标准答案（2026-08-09 复测）

**一句话：不是 Rails/API 慢，是 Windows 把仓库 bind mount 进 Docker 后 Vite 读海量小文件极慢。**

| 探测 | 结果 | 结论 |
|------|------|------|
| `GET /app/login` HTML | ~0.15–0.19s | 后端正常 |
| 容器内 `df -T /app` | **9p** | Docker Desktop 跨 OS 挂载 |
| 容器内 `find /app/app/javascript -name '*.vue' \| wc -l`（约 1127 个） | **10–13s** | 挂载 I/O 瓶颈（冒烟证据） |
| 容器 CPU/内存 | 通常不高 | 不是资源打满 |

页面 HTML 很快返回，浏览器再拉 `/vite-dev/...` 成百上千模块时，目录枚举/读文件都走慢挂载 → 体感「所有请求都很慢」。

**改善（按效果）：**

1. **最有效**：仓库放到 **WSL2 文件系统**（如 `~/code/chatwoot`），在 WSL 里跑 `./deploy/dev-docker-up.sh`
2. **次选**：本机 nvm 跑 Vite，Docker 只跑 Rails/Postgres/Redis（`dev-up` + 本机 pnpm）
3. **治标**：Docker Desktop 开 VirtioFS / 加资源——通常仍远不如 1

**下次有人问「本地为什么慢」：直接答 §5.2.1，不要再花时间测 Rails。**

### 5.3 本机工具链备忘

- Node：可用 **nvm-windows**（已有 Node 24.x 即可）。
- Ruby：未装时不要硬装；Docker 开发栈即可。若要本机 Ruby，Windows 上类似 nvm 的是 **mise**（或 WSL2 + rbenv）。

---

## 6. 产品侧相关约定（部署时别踩）

- 自助 Stripe 订阅已关；功能/限额在 Super Admin 手工开。
- Contact Support：Super Admin → Settings → Contact Support；优先同机 Website Token widget。
- 用户可见「Chatwoot」文案：UI 层用 `replaceInstallationName`，不要写死品牌。

---

## 7. 建议的日常节奏

1. **写功能**：`task/<名>` + 本地 `dev-docker-up`（或 WSL 里同一套）。
2. **给别人看 / 联调**：MR → `test`，本机 `build-push.ps1 test` → `git push codeup test`。
3. **准发布**：`test` 认可后合 `dev`，再 `build-push dev` + push。
4. **上线**：合 `custom`，审批后 `build-push prod` + push。

排障时先分清：是「本地慢」（挂载/Vite）还是「某环境没更新」（忘了 build-push / 流水线 pull 失败 / `.env` 指错）。

---

## 8. 相关文件索引

| 文件 | 内容 |
|------|------|
| [`README.md`](README.md) | 部署操作手册 |
| [`DEV.md`](DEV.md) | 本地开发机用法 |
| [`compose.dev.yml`](compose.dev.yml) | 本地全栈挂载 |
| [`compose.yml`](compose.yml) | 发布环境通用 compose |
| [`build-push.ps1`](build-push.ps1) / `.sh` | 本机构建推仓 |
| [`yunxiao-pipeline-*.yaml`](yunxiao-pipeline-test.yaml) | 云效只 pull 模板 |
| [`env/*.env.example`](env/) | 各环境 / 本地 `.env` 模板 |
| [`Dockerfile.cn`](Dockerfile.cn) | 国内源构建 |
