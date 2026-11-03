# NewAPI：SQLite → PostgreSQL

生产推荐 PostgreSQL。若现网仍是 `./data/one-api.db`（未设置 `SQL_DSN`），按下列顺序迁库，**不要只改 DSN 后直接覆盖**。

## 1. 备份

```bash
cd /opt/1panel/apps/new-api   # 以实际目录为准
cp -a data/one-api.db "data/one-api.db.bak.$(date +%Y%m%d%H%M%S)"
cp -a .env ".env.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
```

## 2. 换成 PgSQL compose

1. 用仓库 `deploy/new-api/compose.yml` 与 `.env.example` 覆盖/合并到部署目录。
2. 填好 `POSTGRES_PASSWORD` / `REDIS_PASSWORD` / `SESSION_SECRET`。
3. `HOST_PORT` 避开 Chatwoot（prod 常用 3000）。

```bash
docker compose up -d postgres redis
# 等 healthy 后启动一次 new-api，让 GORM 建空表
docker compose up -d new-api
sleep 15
docker compose stop new-api
```

## 3. 导入 SQLite 数据

在有 Node 的机器上（或临时容器）用社区迁库脚本把 `one-api.db` 写入 PostgreSQL（表已由 new-api 创建）。

要点：

- `SQL_DSN` / 连接串与 `.env` 一致，例如：  
  `postgresql://newapi:密码@127.0.0.1:5432/new-api`（需临时映射 postgres 端口）或经 `docker compose exec` 同网络访问。
- 迁完后重置各表序列（脚本通常会处理）。
- 再次备份后再 `docker compose up -d`。

参考讨论：[linux.do — new-api 迁移 sqlite 到 postgresql](https://linux.do/t/topic/261672)

## 4. 校验

```bash
docker compose logs -f new-api
curl -sS http://127.0.0.1:${HOST_PORT}/api/status
```

确认后台登录、渠道、令牌与 Chatwoot `CAPTAIN_OPEN_AI_ENDPOINT` 调用正常后，再考虑移除旧 `one-api.db`（建议先只改名保留）。
