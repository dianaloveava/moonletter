# 月信中转同步服务

Cloudflare Worker + R2 的极简对象存储中转：应用把加密后的日志与快照按对象写入，
服务端只保存密文，不接触密钥。

## 部署

```bash
npm install
npx wrangler login
npx wrangler r2 bucket create moonletter-sync
npx wrangler deploy
```

部署完成后记下 Worker 地址（形如 `https://moonletter-relay.<你的子域>.workers.dev`），
在应用的「设置 → 云同步」里选择「中转服务」，填入这个地址与同步 ID。

## 接口

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/health` | 健康检查，返回 `ok` |
| GET | `/v1/o/{ns}/{path...}` | 读对象，不存在返回 404 |
| PUT | `/v1/o/{ns}/{path...}` | 写对象，已存在返回 409，上限 8 MiB |
| DELETE | `/v1/o/{ns}/{path...}` | 删对象 |
| GET | `/v1/list/{ns}?prefix=logs/` | 列对象（`path`/`size`/`etag`/`modified`） |

鉴权用 `Authorization: Bearer {ns}`。`ns` 是应用生成的同步 ID（16 随机字节的
base32，形如 `abcd...`），同时充当局域网关与访问凭据；因为内容本身是端到端加密的，
即使同步 ID 泄露也无法解出数据。

## 本地开发

```bash
npx wrangler dev --port 8787
```

本地模式下 R2 由 miniflare 模拟，数据存在 `.wrangler/` 下；`npm install` 与 `npm run check`（`tsc --noEmit`）用于安装依赖与类型检查。
