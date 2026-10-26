# 部署

## 前置条件

- Docker Desktop 或 OrbStack 已启动，且支持 `linux/386` 镜像。Apple Silicon 走 QEMU 模拟，跑这套 2000 年的 2D 服务端性能足够。
- 首次构建需要访问 `archive.debian.org`、Docker Hub。若公司网络拦 Docker Hub，先按下面手动拉基础镜像。
- 磁盘：镜像约 700 MB，数据另计；内存：容器约 2 GB 上限。

## 1. 准备代码

```bash
git clone https://github.com/dongfangzan/stoneage-2.5-docker.git stoneage
cd stoneage
```

HTTPS 到 github.com 超时的话，用 SSH 443：

```bash
git clone ssh://git@ssh.github.com:443/dongfangzan/stoneage-2.5-docker.git stoneage
cd stoneage
```

## 2. 配置（可选）

```bash
cp .env.example .env
```

| 变量 | 默认 | 作用 |
| --- | --- | --- |
| `SERVER_BIND` | `0.0.0.0` | 端口绑定地址。`127.0.0.1` 只允许本机 |
| `SERVER_PORT` | `9065` | 宿主机端口 |
| `DB_ROOT_PASSWORD` | `sa_local_root` | MariaDB root 口令，saac 也用它连库 |
| `AC_PASS` | `test` | saac/gmsv 握手口令，两个容器自动同步 |

`.env` 已被 git 忽略。**首次初始化过数据库后再改 `DB_ROOT_PASSWORD`，只改 `.env` 不够**：旧库里还是旧口令，需要进库 `ALTER USER` 同步，或者 `./scripts/reset.sh` 重来。

## 3. 基础镜像

`up.sh` 会自动处理，手动等价命令：

```bash
docker pull --platform linux/386 i386/debian:buster-slim
docker tag i386/debian:buster-slim stoneage-base:i386
docker pull mariadb:10.11
docker tag mariadb:10.11 stoneage-mariadb:10.11
```

用本地标签而不是直接在 `FROM` 里写远程名，是因为当前网络下 BuildKit 取 Docker Hub token 会超时。构建固定用 `DOCKER_BUILDKIT=0`。

## 4. 启动

```bash
./scripts/up.sh
```

脚本做的事：

1. 检查 Docker 是否在运行。
2. 缺基础镜像就拉取并打本地标签。
3. `DOCKER_BUILDKIT=0 docker build -t stoneage-25:local ./server-2.5`。
4. `docker compose up -d`。
5. 轮询 9065，就绪后打印局域网地址；超时则输出容器状态和 gmsv 日志。

看到 `就绪` 和 `0.0.0.0:9065->9065/tcp` 即成功。

## 构建原理

服务端是 32 位 x86 ELF，现代 64 位环境直接编不过。`Dockerfile` 的做法：

- 基础镜像 `i386/debian:buster-slim`，整个构建和运行都在 386 用户态。
- apt 源切到归档的 `archive.debian.org`，放行过期签名。
- 把 libc/zlib/gnutls 等降级到与 `-dev` 包一致的 buster 版本，否则头文件和运行库版本对不上。
- 安装 `libmariadb-dev`，再软链成 `/usr/include/mysql`，兼容源码里的 `<mysql.h>`。
- 用 `-std=gnu89` 编译：2.5 的访问器是 gnu89 inline 语义，用 gnu99/gnu11 会链接缺符号。
- 两个二进制都 `strip`，入口按容器角色区分。

`docker/entrypoint-saac.sh` 和 `entrypoint-gmsv.sh` 只做运行期接线：等依赖端口、把 `DB_HOST`/`AC_PASS`/`AC_HOST` 写进 `acserv.cf`、`setup.cf`，然后 `exec` 主进程，保证信号能传到。

## 5. 验证

```bash
./scripts/status.sh
docker compose ps
lsof -nP -iTCP:9065 -sTCP:LISTEN
```

三个容器应为 `Up`，db 为 `healthy`，9065 有监听。再按 [client.md](client.md) 用客户端实际登录一次。

## 6. 常用操作

```bash
docker compose logs -f gmsv     # 游戏服日志
docker compose logs -f saac     # 账号服日志
./scripts/down.sh               # 停服，数据保留
./scripts/reset.sh              # 删卷重建，数据清空
./scripts/backup.sh             # 备份数据库和角色
```

## 升级 / 改代码后重编

改 `server-2.5/` 下任何 C 代码或配置后：

```bash
./scripts/up.sh
```

`up.sh` 会重新构建并 `compose up`，容器检测到镜像变化会重建。角色在命名卷 `saac-char`，数据库在 `db-data`，重建容器不丢。

只改 `setup.cf`、`gmset.txt`、`data/` 这类运行期文件，也必须重编镜像——它们是在构建时 `COPY` 进镜像的，不是挂载。改完 `up.sh` 即可。

## 迁移到另一台机器

1. 旧机：`./scripts/backup.sh`，把 `backups/` 下两个文件拷走。
2. 新机：clone 仓库，`cp .env.example .env` 并设成相同的 `DB_ROOT_PASSWORD`，`./scripts/up.sh`。
3. 新机：`./scripts/restore.sh <db.sql> <char.tgz>`。

`.env` 里的口令要一致，否则恢复出来的库连不上。
