# 运维

## 账号

自动注册默认开着：任意账号密码首次登录即建号。预置：

| 账号 | 密码 | 用途 |
| --- | --- | --- |
| `player` | `123456` | 普通玩家 |
| `gm` | `gm` | GM，指令密码也是 `gm` |

关自动注册：改 `server-2.5/saac/acserv.cf` 的 `AutoReg 0`，然后重编。

手动建号（口令明文，和这套老服务端一致）：

```bash
docker compose exec -T db mysql -uroot -p"$DB_ROOT_PASSWORD" sa -e \
  "INSERT IGNORE INTO user_table(Name,Pass,RegTime,Path) VALUES('名字','密码',NOW(),'char/0x0');"
```

改密码：

```bash
docker compose exec -T db mysql -uroot -p"$DB_ROOT_PASSWORD" sa -e \
  "UPDATE user_table SET Pass='新密码' WHERE Name='名字';"
```

改 GM：`server-2.5/gmsv/data/gmset.txt` 每行是 `账号 指令密码 GM等级`，默认 `gm gm 3`。改完重编。等级 1 工具/传送，2 给物给钱，3 系统级。

## GM 指令

聊天框输入，`gm` 是指令密码前缀，例如：

```text
gm gold 1000000
gm level 140
gm exp 9999
gm petmake 353 140
gm additem 18537
gm warp 1000 30 30
noenemy on
```

常用：

| 指令 | 作用 |
| --- | --- |
| `gm level 数值` | 改等级 |
| `gm exp 数值` | 改经验 |
| `gm gold 数量` | 给石币 |
| `gm petmake 宠物ID 等级` | 造宠 |
| `gm additem 道具ID 数量` | 给道具 |
| `gm settrans 数值` | 改转生 |
| `gm warp 地图 x y` | 传送 |
| `gm metamo 图号` | 变身 |
| `gm reset all` | 重载资源 |
| `gm petlevelup 栏位 等级` | 宠物升级 |
| `gm shutup 账号` / `gm silent 账号 分钟` | 禁言 |
| `gm kick` 系列 | 踢人/锁号 |
| `noenemy on/off` | 关/开遇敌（仅自己） |
| `gm shutdown 分钟` | 定时关服 |
| `gm help` / `gm help all` | 指令表 |

## 数据在哪

| 数据 | 位置 |
| --- | --- |
| 角色存档 | Docker 卷 `saac-char`（`/app/saac/char`） |
| 账号、家族、邮件库 | Docker 卷 `db-data`（`/var/lib/mysql`） |
| 源码、DATA、配置 | 仓库 `server-2.5/` |

卷不会因为 `down` 或删容器消失，只有 `reset.sh` / `down -v` 或手动 `docker volume rm` 会清。

```bash
docker volume ls | grep stoneage
```

## 备份与恢复

```bash
./scripts/backup.sh
```

产出 `backups/db-<时间>.sql` 和 `backups/char-<时间>.tgz`。建议拷到仓库外或另一台机器，别只留本机。

恢复（会覆盖现有数据，有确认提示）：

```bash
./scripts/restore.sh backups/db-2026-10-26-120000.sql backups/char-2026-10-26-120000.tgz
```

手工 dump：

```bash
docker compose exec -T db mysqldump -uroot -p"$DB_ROOT_PASSWORD" sa > backup.sql
```

## 改玩法

改 `server-2.5/gmsv/setup.cf`，每次改完 `./scripts/up.sh` 重编。

| 目的 | 键 |
| --- | --- |
| 经验倍率 | `battleexp=300` |
| 出生等级/转数 | `LV=1`、`TRANS=0` |
| 出生金钱 | `GOLD=1000000` |
| 出生宠物 | `NPRIDE=3`（1 虎、2 雷、3 虎加雷）、`PET1..PET4`（宠物 ID） |
| 出生道具 | `ITEM1..ITEM15`（道具 ID） |
| 等级上限 | `LEVEL=140`、`MAXLEVEL=160` |
| 宠物转数 | `PETTRANS=-1` |
| 服务器名 | `gameservname=`、`gameservid=` |
| 遇敌表 | `encountfile=./data/encount.txt` |

### 改成纯 PK 服

1. **关野外遇敌**：清空 `server-2.5/gmsv/data/encount.txt`，或把 `encountfile` 指向一个空文件。
2. **出生点改到 PK 图**：出生坐标在 `server-2.5/gmsv/char/char_data.c` 的 `elders[]` 表，按家乡索引取坐标，改前四项的 `floor/x/y`。
3. **出生即满级**：`LV=160`，`battleexp` 拉高。
4. **500 点自由配点**：当前是原版 20 点档，要改 `char_data.c` 的建号配点逻辑，并在大厅加洗点 NPC。属于代码改动，不是配置项。
5. **只留大厅**：把传送 NPC 和 `data/map` 里用不到的地图逐步裁掉。

## 日志

```bash
docker compose logs -f gmsv
docker compose logs -f saac
```

日志是 GB2312，终端乱码就转：

```bash
docker compose logs --tail=200 gmsv | iconv -f gb18030 -t utf-8
```

## 改端口

改 `.env` 的 `SERVER_PORT`，`docker compose up -d`。容器内仍是 9065。

## 排障

见 [troubleshooting.md](troubleshooting.md)。
