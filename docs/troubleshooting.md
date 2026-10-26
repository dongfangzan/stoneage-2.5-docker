# 排障

先看同一份现场，再动手：

```bash
docker compose ps
docker compose logs --tail=80 gmsv
docker compose logs --tail=80 saac
docker compose logs --tail=80 db
lsof -nP -iTCP:9065 -sTCP:LISTEN
```

## 9065 被占用

```bash
docker compose down
docker ps -a | grep 9065
docker rm -f stoneage-gmsv-1
./scripts/up.sh
```

如果之前 `up` 因端口冲突失败过，gmsv 容器可能以“无网络”状态残留：`docker exec` 里 `getent hosts saac` 解析失败、日志为空。删掉容器重开即可。

## Docker Hub 取 token 超时

构建前需要 `i386/debian:buster-slim` 和 `mariadb:10.11`。用 `./scripts/up.sh`，它走本地标签和 `DOCKER_BUILDKIT=0`。手动：

```bash
docker pull --platform linux/386 i386/debian:buster-slim
docker tag i386/debian:buster-slim stoneage-base:i386
docker pull mariadb:10.11
docker tag mariadb:10.11 stoneage-mariadb:10.11
```

## 构建时 apt 失败

`archive.debian.org` 不通，或系统时间偏差过大。检查代理、`curl -I http://archive.debian.org/debian/`，校准时间后重试。Dockerfile 已经带了 `Acquire::Check-Valid-Until=false`。

## `exec format error`

基础镜像不是 386。确认：

```bash
docker image inspect stoneage-base:i386 --format '{{.Architecture}}'
```

应为 `386`。不对就重新按上面两条命令打标签。Apple Silicon 还需要 Docker 的 QEMU 模拟可用，OrbStack 默认支持。

## db 一直 `starting` / `unhealthy`

```bash
docker compose logs db
```

常见原因是卷里已有旧库、口令和新 `.env` 不一致。要保留数据就进容器用旧口令 `ALTER USER`；不要数据就 `./scripts/reset.sh`。

## 编译报缺少符号

必须用 `gnu89`。确认没有覆盖 `CFLAGS`，直接 `./scripts/up.sh`。

## 登录后立刻断开

按顺序查：

1. 虚拟机里 `ping <宿主 IP>` 通不通；虚拟机网络是不是桥接。
2. 端口是不是 9065，防火墙有没有拦。
3. 服务器名、IP、端口三者是否和登录器一致。
4. 客户端 DATA 和服务端是否同版本、握手密钥是否 `cary`。
5. `docker compose logs gmsv` 有没有握手/密钥报错。

## 进图黑屏

踩到服务端有、客户端没有的地图。回村再走，或裁掉 `gmsv/data/map` 里多余的地图并重编。

## 客户端闪退 / 花屏

- 闪退：卸搜狗/QQ 输入法，默认英文输入法。
- 花屏：16 位色，`dxdiag` 里禁用 DirectDraw；仍不行换 Win7 虚拟机。
- 杀软拦截：STW、`sa_2903.exe`、`sa_ext.dll` 加白。

## gmsv 启动即退

```bash
docker compose logs --tail=120 gmsv | iconv -f gb18030 -t utf-8
```

多数是 DATA 缺文件、`setup.cf` 改坏、或磁盘满。核对最近改动，必要时 `git diff` 回退。

## 端口能连但一直停在连接中

saac/gmsv 握手失败。检查两个容器的 `AC_PASS` 是否一致（都来自同一 `.env`），以及 `docker compose exec gmsv getent hosts saac` 能否解析。

## 深度清理

```bash
docker compose down -v                  # 删容器和两个数据卷
docker image rm stoneage-25:local       # 删镜像，下次重编
./scripts/up.sh
```

`down -v` 会清空角色和数据库，先备份。
