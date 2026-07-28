# Jingqi Chatwoot 自动化部署指南

## 目标

| 环境 | 分支 | 镜像 tag | 域名示例 | 何时部署 |
|------|------|----------|----------|----------|
| **prod** | `custom` | `prod-latest` | `chat.公司域名.com` | `dev` 测通后人工晋升 |
| **dev** | `dev` | `dev-latest` | `chat-dev.公司域名.com` | 合入 `dev` 后自动部署（准发布） |
| **test** | `test` | `test-latest` | `chat-test.公司域名.com` | 合入/推送 `test` 后自动部署（随时覆盖） |

```
task/* ──MR──► test ──认可──► dev ──确认发布──► custom
               test 栈         dev 栈              prod
             （随时覆盖）    （准发布）           （审批）
```

不做 per-task preview：任务只在分支开发，验证靠唯一的 `test` 环境覆盖更新。

---

## 第 0 步：准备基础设施（一次性）

1. **服务器**（可先单机）：安装 Docker + Docker Compose。
2. **镜像仓库**：本机私有仓或阿里云 ACR（业务机**只 pull，不 build**）。
3. **域名 / 反代**：把三个环境指到不同端口或不同 compose 项目。
4. **Codeup + 云效**：三轨流水线分别绑 `test` / `dev` / `custom`。

每套环境各自一份目录与数据，**不要共用 Postgres/Redis**：

```text
/opt/1panel/apps/chatwoot/chatwoot-prod/     # 正式
/opt/1panel/apps/chatwoot/chatwoot-dev/      # 准发布（推荐名）
/opt/1panel/apps/chatwoot/chatwoot-test/     # 试验场
```

现网兼容：若仍使用 `chatwoot-staging` 目录，即 **dev 环境**，流水线可继续指向该路径；新装请用 `chatwoot-dev`。

三套全开时注意内存；吃紧时可将 `test` 按需启停。

---

## 第 1 步：每套环境放配置

| 环境 | 模板 | 推荐部署目录 | 默认端口 |
|------|------|--------------|----------|
| 正式 | `deploy/env/chatwoot-prod.env.example` | `chatwoot-prod` | 3000 |
| 准发布 | `deploy/env/chatwoot-dev.env.example` | `chatwoot-dev` | 3002 |
| 测试 | `deploy/env/chatwoot-test.env.example` | `chatwoot-test` | 3004 |

一键初始化（自动生成 `SECRET_KEY_BASE` / DB / Redis 密码，SMTP 需手填）：

```bash
chmod +x deploy/bootstrap-env.sh
./deploy/bootstrap-env.sh prod /opt/1panel/apps/chatwoot/chatwoot-prod
./deploy/bootstrap-env.sh dev  /opt/1panel/apps/chatwoot/chatwoot-dev
./deploy/bootstrap-env.sh test /opt/1panel/apps/chatwoot/chatwoot-test
```

换机器复用时：保持目录命名，改模板里的 `IMAGE` 与 `FRONTEND_URL` 即可。

---

## 第 2 步：固化发布链路（本机构建 → push 私有仓 → 流水线 pull）

业务机**禁止** `docker build`。标准路径：

```
本机/构建机 build-push  ──►  私有仓 (*-latest + $SHA)
                                    │
git push codeup <分支>  ──►  云效流水线  ──►  业务机 compose pull && up
```

### 2.1 一键构建推送

先确保已 `docker login 100.65.76.62:5000`（本机 Docker Desktop 需配 insecure-registries）。

```bash
# Git Bash / WSL / Linux（默认用 deploy/Dockerfile.cn）
./deploy/build-push.sh test    # → test-latest + $SHA
./deploy/build-push.sh dev     # → dev-latest
./deploy/build-push.sh prod    # → prod-latest（分支应为 custom）
```

Windows PowerShell：

```powershell
.\deploy\build-push.ps1 test
.\deploy\build-push.ps1 dev
.\deploy\build-push.ps1 prod
```

| 参数 / 环境变量 | 作用 |
|-----------------|------|
| `--cn` / 默认 | 使用 `deploy/Dockerfile.cn` |
| `--dockerfile PATH` | 指定 Dockerfile |
| `--no-push` / `-NoPush` | 只 build 不推 |
| `REGISTRY_IMAGE=` | 覆盖仓库地址（默认 `100.65.76.62:5000/jingqi/chatwoot`） |

| 分支 | 可变 tag | 建议同时打 |
|------|----------|------------|
| `test` | `test-latest` | `$SHA` |
| `dev` | `dev-latest` | `$SHA` |
| `custom` | `prod-latest` | `$SHA`、可选 `v*` |

**顺序**：先 `build-push`，再 `git push`（保证流水线 pull 时镜像已在仓里）。若已先 push：镜像推完后在云效对该流水线点「运行」。

### 2.2 云效流水线（只 pull，不 build）

| 流水线 | 文件 | 触发分支 | 目录 / tag | 云效 ID |
|--------|------|----------|------------|---------|
| 景齐-Chatwoot测试版 | `yunxiao-pipeline-test.yaml` | `test` | `chatwoot-test` / `test-latest` | `5160619` |
| 景齐-Chatwoot-dev版 | `yunxiao-pipeline-dev.yaml` | `dev` | 现网 `chatwoot-staging` 或 `chatwoot-dev` / `dev-latest` | `5158422` |
| 景齐-Chatwoot正式版 | `yunxiao-pipeline-prod.yaml` | `custom` | `chatwoot-prod` / `prod-latest`（首批暂停审批） | `5158432` |

可变 tag 只保留「当前指向」；不要为每个 task 长期留独立镜像。

---

## 第 3 步：服务器上手动更新（排障用）

流水线正常时不必手跑。排障：

```bash
cd /opt/1panel/apps/chatwoot/chatwoot-test   # 或 chatwoot-staging / chatwoot-prod
docker compose pull
docker compose up -d
docker compose exec -T rails bundle exec rails db:chatwoot_prepare
# 首次空库也可用：docker compose run --rm rails bundle exec rails db:chatwoot_prepare
docker compose ps
```

现网 compose 文件名多为 `docker-compose.yml`（`docker compose` 同样识别）。

---

## 第 4 步：研发日常（含 AI）

1. 从 `test`（或 `dev`）拉任务分支：`git checkout -b task/xxx test`
2. 开发完：`git push -u codeup task/xxx`
3. 开 MR → **合入 `test`**
4. 在合入后的 `test` 提交上：`./deploy/build-push.sh test` → `git push codeup test`（若 MR 已推过则云效重跑或再 push）
5. 试验认可 → MR **`test` → `dev`** → `build-push.sh dev` → 推 `dev`
6. 决定上线 → MR **`dev` → `custom`** → `build-push.sh prod` → 推 `custom`（审批）

禁止：任务分支直接推 `custom`；无约定时不要直推 `dev`。
**禁止**：在业务机 `docker build` / 跑 `deploy-build.sh`（该脚本仅遗留排障，优先用本机 `build-push`）。

---

## 第 5 步：发版检查清单（`dev` → `custom`）

- [ ] `dev` 环境功能/回归 OK
- [ ] 迁移脚本可逆或已备份正式库
- [ ] `FRONTEND_URL`、邮件、渠道密钥为正式配置
- [ ] Super Admin 客服 token / 品牌配置已在正式环境配好
- [ ] 审批人确认后再合 `custom`

---

## 本目录文件

| 文件 | 用途 |
|------|------|
| `build-push.sh` / `build-push.ps1` | **本机**构建并推私有仓（主路径） |
| `compose.yml` | 通用生产向 compose（用环境变量选镜像） |
| `deploy.sh` | 服务器上「拉镜像并重启」（排障） |
| `deploy-build.sh` | 遗留：业务机本地编镜像（不推荐） |
| `bootstrap-env.sh` | 从模板初始化目录 + 生成密钥 |
| `env/*.env.example` | 各环境 `.env` 模板（无真实密钥） |
| `Dockerfile.cn` | 国内源构建用 Dockerfile |
| `yunxiao-pipeline-*.yaml` | 云效流水线 YAML 镜像（只 pull） |
