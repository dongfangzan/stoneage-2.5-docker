# 安全

这套东西是 2000 年代的 C 代码，把它当“能跑的古董”而不是“安全网关”看待。默认配置适合本机和小范围，公网暴露前按下单子过一遍。

## 当前暴露面

- 只发布 `gmsv` 的 9065。`saac` 的 9300 和 MariaDB 的 3306 只在 Docker 内网。
- 服务端在 `linux/386` 容器里以 root 运行，镜像基于已 EOL 的 Debian buster。
- 游戏协议是裸 TCP，账号密码和 GM 密码都在明文协议里，没有 TLS。
- 账号密码在 `user_table` 里明文存储。

## 已做的代码加固

来自 Mimosa 扫描结果，均已重编译验证：

- `saac/char.c`：`strncpy` 后用 `strlen(src)` 定位结尾，源串超长会越界；改为 `sizeof-1` 截断并显式补 NUL。
- `saac/char.c`、`saac/acfamily.c`、`saac/mail.c`、`saac/sasql.c`、`gmsv/main.c`、`gmsv/buf.c`、`gmsv/net.c`、`gmsv/lssproto_serv.c`：宏拼接、跨行、`#ifdef` 分隔的格式串改成完整字面量，宏作为 `%s` 参数传入，消除 CWE-134。
- `acfamily.c` 的家族名等字段加 `%.32s` / `%.256s` 上限，避免未终止数组被无界读取。

修复后上述文件的高危计数为 0。这不等于代码审计通过，只覆盖了扫描命中的模式。

## 公网前必改

1. **数据库口令**：`.env` 的 `DB_ROOT_PASSWORD`。已初始化过的库要同步 `ALTER USER`，否则连不上。
2. **握手口令**：`.env` 的 `AC_PASS`，两个容器会自动同步。
3. **GM 口令**：`server-2.5/gmsv/data/gmset.txt` 的 `gm gm 3`，同时改 `user_table` 里 `gm` 的密码。
4. **决定自动注册**：`AutoReg 1` 意味着谁都能建号。公开服建议改 `0` 并手动发号，或至少盯着日志。
5. **服务器名**：`setup.cf` 的 `gameservname` / `gameservid`，别留着默认名。
6. **备份**：公网环境每天 `./scripts/backup.sh`，备份放到另一台机器。
7. **防火墙**：只放 9065。macOS 防火墙允许 OrbStack/Docker 入站，不要整机全开。

## 默认值清单

| 项 | 默认 | 位置 |
| --- | --- | --- |
| MariaDB root | `sa_local_root` | `.env` / compose |
| saac 握手 | `test` | `.env` |
| GM 账号 | `gm` / `gm` | `db/init.sql`、`data/gmset.txt` |
| 玩家示例 | `player` / `123456` | 运行时自动注册 |
| 端口绑定 | `0.0.0.0` | `.env` 的 `SERVER_BIND` |

只在本机玩就把 `SERVER_BIND` 设成 `127.0.0.1`。

## 剩余风险

- **明文协议**：抓包能看到口令。别把常用密码拿来建号。
- **无速率限制**：登录、建号都能被刷。公开前最好在前面挡一层，或至少定期看连接数。
- **无 TLS**：客户端太老，套 TLS 要改协议，成本高。
- **老依赖**：buster、gnutls 3.6、MariaDB 10.11 都会陆续停更，镜像要自己维护。
- **单进程内存模型**：gmsv 预申请约 2 GB，单世界一实例；异常退出会丢最后一段存档。
- **数据表 MyISAM**：不支持事务，崩溃时可能表损坏。备份比修复便宜。
- **二进制来源**：本仓库自己编译，不依赖论坛加壳端；但上游源码没有许可证和正式审计。

## 入侵迹象

- `docker compose logs gmsv | iconv -f gb18030 -t utf-8` 里出现陌生 GM 指令、异常刷物。
- 数据库里出现不认识的账号，或 `user_table` 条数暴涨。
- 9065 的连接数长期异常高。

出事就先 `down`，备份现场（`docker compose logs > incident.log`、`./scripts/backup.sh`），再排查。
