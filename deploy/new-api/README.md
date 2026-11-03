# Jingqi NewAPI 部署（PostgreSQL）

与 Chatwoot 同机时的约定（见 `deploy/LESSONS.md`）：Chatwoot prod 占宿主机 **3000**，NewAPI 建议 **3010**（或其它空闲端口），经 1Panel / OpenResty 反代对外。

| 项 | 值 |
|----|----|
| 镜像 | `calciumion/new-api:latest` |
| 数据库 | **PostgreSQL 15**（`SQL_DSN`） |
| 推荐目录 | `/opt/1panel/apps/new-api` |
| 更新 | `./update.sh` 或 1Panel「应用商店 → 可更新」 |

## 全新安装

```bash
sudo mkdir -p /opt/1panel/apps/new-api
cd /opt/1panel/apps/new-api
# 从本仓库拷贝
cp /path/to/chatwoot/deploy/new-api/compose.yml .
cp /path/to/chatwoot/deploy/new-api/.env.example .env
cp /path/to/chatwoot/deploy/new-api/update.sh .
chmod +x update.sh
# 编辑 .env：密码、HOST_PORT、SESSION_SECRET
docker compose pull
docker compose up -d
```

Chatwoot Super Admin → Captain：`CAPTAIN_OPEN_AI_ENDPOINT` 指到 NewAPI 根地址（容器互联可用宿主机网关或反代域名）。

## 仅更新镜像（已是 PgSQL）

```bash
cd /opt/1panel/apps/new-api
./update.sh
```

脚本会备份 `.env` / compose，并在 postgres 已运行时尝试 `pg_dump`。

## 仍在用 SQLite 时

先按 [`migrate-sqlite-to-pgsql.md`](./migrate-sqlite-to-pgsql.md) 迁库，再更新镜像。

## 1Panel 应用商店路径

若当初用 1Panel 安装 New API：也可在面板「应用商店 → 可更新」升级镜像；同时检查环境变量是否已设 `SQL_DSN=postgresql://...`。面板升级**不会**自动把 SQLite 迁到 PgSQL。
