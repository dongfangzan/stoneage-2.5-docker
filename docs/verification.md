# 验证记录

- 日期：2026-10-26
- 宿主：macOS 27.0.0 (arm64)，OrbStack
- 代码状态：已删除历史 `.o` / `.a` / `.exe` / 日志，只留源码、DATA、配置
- 目的：确认清理后仍能从源码构建、启动、握手、读写数据

## 1. 从源码构建

```bash
DOCKER_BUILDKIT=0 docker build -t stoneage-25:local ./server-2.5
```

结果：成功。

- 编译器 gcc 8.3.0，`-std=gnu89`，目标 `linux/386`。
- 产物镜像 334 MB。
- 构建日志里只有预期内的平台警告（arm64 宿主跑 386 镜像），无编译错误。

## 2. 启动

```bash
./scripts/up.sh
```

结果：三个容器全部 `Up`，db `healthy`，脚本在 9065 就绪后返回：

```
NAME              IMAGE                    STATUS                   PORTS
stoneage-db-1     stoneage-mariadb:10.11   Up (healthy)             3306/tcp
stoneage-gmsv-1   stoneage-25:local        Up                       0.0.0.0:9065->9065/tcp
stoneage-saac-1   stoneage-25:local        Up
```

## 3. 端口与握手

```bash
lsof -nP -iTCP:9065 -sTCP:LISTEN
python3 -c 'import socket; s=socket.create_connection(("127.0.0.1",9065),3); print(s.getpeername())'
```

- 9065 由 OrbStack 监听（IPv4/IPv6 `*:9065`）。
- TCP 连接成功：`('127.0.0.1', 9065)`。

gmsv 日志：

```
载入 NPC 数据文件...确认载入 NPC 4952 ...成功
初始化 2981 个地图坐标点...成功
与AC服务器连接成功
```

saac 日志：

```
同步: 1
服务器名称正确 我的石器
```

## 4. 数据

```bash
docker compose exec -T db mysql -uroot -p... -e 'select count(*) from sa.user_table'
```

- 重启和重建容器后账号仍在，`gm` 与 `player` 两条记录保留。

## 5. 备份 / 恢复

```bash
./scripts/backup.sh
echo y | ./scripts/restore.sh backups/db-...sql backups/char-...tgz
```

- 备份产出 `db-*.sql`（2.7 KB）和 `char-*.tgz`（2.0 KB）。
- 恢复后容器自动拉起，账号条数仍为 2。

## 6. 公网隧道

```bash
./scripts/tunnel.sh pinggy
```

- 分配到 `tcp://twfqk-222-197-110-59.run.pinggy-free.link:38215`。
- 从本机经公网回连成功：`('139.162.8.164', 38215)`。
- `bore.pub:7835` 在本网络超时，未验证成功。

## 未覆盖

- **客户端实机登录**：需要 Windows 虚拟机，本次只在服务端验证到握手。
- **长时间稳定性**：只跑了短时进程，没有压测和跨天运行。
- **裸机 Linux x86_64**：只在 Apple Silicon + OrbStack 上验证。
- **Tailscale / 路由器端口映射**：只写了步骤，没有实测。
- **pinggy 下的客户端登录**：只验证了 TCP 端口可达，没有在客户端里完整登录。
- **全新机器**：没有在干净机器上完整走一遍 clone 到登录。

这些属于使用前应自己补测的部分。
