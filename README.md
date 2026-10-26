# 石器时代 2.5 服务端（Docker 一键部署）

一套已经跑通的石器时代 2.5 私服环境：`saac`（账号服）+ `gmsv`（游戏服）+ MariaDB，全部装在 `linux/386` 容器里，一条命令启动。服务端代码取自 longzoro 血统的公开 2.5 源码，补了 32 位构建配方、若干高危写法加固和开箱配置。

适合本机单机、局域网，或加一层内网穿透后自己在外网玩。

> **已验证状态（2026-10-26，macOS + OrbStack）**：源码从零编译通过，数据库初始化、自动注册、saac/gmsv 握手成功，`0.0.0.0:9065` 处于监听，2135 个 NPC 与 706 个地图文件载入，无崩溃。验证记录见 [docs/verification.md](docs/verification.md)。

## 这是什么，不是什么

- **是**：2.5 服务端源码的容器化部署方案，能登录、能打怪、能用 GM 指令，带备份/恢复脚本。
- **不是**：官方服务端；也不是《疯狂原始人》2.0 原版。它只是同架构的 2.5，用来先把链路跑通。
- 客户端是华义 2.5 血统（`sa_2903.exe`，服务端密钥 `cary`），与服务端 DATA 版本匹配。

## 架构

```
Windows 虚拟机 / 另一台电脑
        │  TCP 9065
        ▼
┌──────────────────────────────────────────┐
│ Docker 网络                               │
│                                          │
│  gmsv :9065 ──握手:9300──▶ saac ──▶ db   │
│  (游戏服)                  (账号服)  (MariaDB)
│         ▲                    │           │
│         └── saac-char 卷 ◀───┘           │
└──────────────────────────────────────────┘
```

只有 `gmsv` 的 9065 端口对外发布，`saac` 和数据库只在 Docker 内网里。

## 快速开始

### 前置

- macOS（Apple Silicon 也行，走模拟）或 Linux x86_64；Docker Desktop / OrbStack 可用。
- 约 2 GB 内存、2 GB 磁盘给容器，另需约 2 GB 给客户端虚拟机。
- 首次构建要能访问 `archive.debian.org`（装 32 位编译依赖）。

### 启动服务端

```bash
git clone <本仓库地址> stoneage && cd stoneage
cp .env.example .env          # 想改端口/口令就改，默认也能直接跑
./scripts/up.sh
```

`up.sh` 会准备基础镜像、用旧版 builder 构建 `linux/386` 镜像、启动 Compose，并等到 9065 监听后打印局域网地址。停止和重置：

```bash
./scripts/down.sh             # 停服，保留角色和数据库
./scripts/reset.sh            # 清空全部数据后重开
```

查看状态：`./scripts/status.sh`；日志：`docker compose logs -f gmsv`。

### 连客户端

客户端约 496 MB，**不在仓库里**，按下面的地址自己下：

| 资源 | 地址 | 说明 |
| --- | --- | --- |
| 2.5 Windows 客户端 | <https://99ds.com/downloads/windows/Stoneage2.5-Windows.rar> | SHA-256 `b311e21f7b63e7b5ca40c778fb74fffd02ea7daca4590a6b74d0aa2a4ef2b9a8`，解压密码无 |
| 服务端源码上游 | <https://github.com/chenmingbiao/stone-age> | 本仓库的代码基线 |
| 基础镜像 | `docker pull --platform linux/386 i386/debian:buster-slim`、`docker pull mariadb:10.11` | `up.sh` 会自动处理 |

客户端跑在 Windows 虚拟机里，虚拟机网络必须选**桥接**，登录器填宿主机的局域网 IP 和端口 9065。完整步骤、兼容性设置和常见报错见 [docs/client.md](docs/client.md)。

账号：任意账号密码首次登录会自动注册；预置玩家 `player` / `123456`，GM `gm` / `gm`（GM 指令密码也是 `gm`）。

## 从家里 / 外网访问

- **同一局域网**：`./scripts/status.sh` 或 `ipconfig getifaddr en0` 取 Mac 的 IP，客户端填 `<IP>:9065`。虚拟机用桥接，不要 NAT。
- **外网**：推荐 Tailscale，装完两端登录同一账号，用 Mac 的 `100.x` 地址直连，不用动路由器。端口映射、DDNS、frp 等做法和注意事项见 [docs/remote-access.md](docs/remote-access.md)。
- 只允许本机连：在 `.env` 里设 `SERVER_BIND=127.0.0.1`。

## 账号与 GM

- 自动注册默认开启（`server-2.5/saac/acserv.cf` 的 `AutoReg 1`）。
- GM 名单在 `server-2.5/gmsv/data/gmset.txt`，默认 `gm gm 3`。
- 常用指令（聊天框输入）：`gm gold 1000000`、`gm level 140`、`gm petmake 353 140`、`gm additem 18537`、`noenemy on`。

完整操作、改规则、备份恢复见 [docs/operations.md](docs/operations.md)。

## 当前配置

| 项 | 值 |
| --- | --- |
| 服务器名 | 我的石器 |
| 经验倍率 | 300 倍（`battleexp=300`） |
| 出生 | 1 级、100 万石币、虎 + 雷 |
| 等级上限 | 160（普通 140） |
| 转生 | 出生 0 转，人物可 5 转，宠物不转 |
| 端口 | 9065 / 账号服 9300 / MariaDB 3306（仅内网） |

改法见 [docs/operations.md](docs/operations.md#改玩法)。

## 文档

| 文档 | 内容 |
| --- | --- |
| [docs/deploy.md](docs/deploy.md) | 从零部署、构建原理、配置项、升级 |
| [docs/client.md](docs/client.md) | 客户端下载、Windows 虚拟机、登录器与兼容性 |
| [docs/remote-access.md](docs/remote-access.md) | 局域网 / Tailscale / 端口映射 / 防火墙 |
| [docs/operations.md](docs/operations.md) | GM、账号、备份恢复、改玩法、数据位置 |
| [docs/troubleshooting.md](docs/troubleshooting.md) | 端口占用、编译超时、黑屏、闪退等 |
| [docs/security.md](docs/security.md) | 已做加固、公网前必改项、剩余风险 |
| [docs/resources.md](docs/resources.md) | 资源与论坛出处、版本判断、为什么客户端不入库 |
| [docs/verification.md](docs/verification.md) | 本机实际验证记录 |
| [docs/research/](docs/research/) | 版本谱系、稳定性、客户端来源、疯狂原始人专项调研 |

## 目录

```
.
├── docker-compose.yml
├── .env.example
├── scripts/                 # up / down / reset / status / backup / restore
├── server-2.5/
│   ├── Dockerfile           # linux/386 + gnu89 构建
│   ├── db/init.sql
│   ├── docker/entrypoint-*.sh
│   ├── saac/                # 账号服
│   └── gmsv/                # 游戏服 + 2.5 DATA
└── docs/
```

## 安全

默认口令（数据库 `sa_local_root`、握手 `test`、GM `gm`）只适合本机。公网暴露前至少做三件事：改 `.env` 口令、改 GM 口令、决定是否关自动注册。详见 [docs/security.md](docs/security.md)。

## 来源与许可

- 代码基线：[chenmingbiao/stone-age](https://github.com/chenmingbiao/stone-age)，longzoro / 龙王 2006 血统（`saac/main.c:382` 的版权串、`:230` 的 `longzoro-` 握手指纹），上游未附许可证。
- 客户端：[99ds.com](https://99ds.com) 分发的华义 2.5 客户端。
- 仅用于学习和自用，不涉及商业运营。游戏著作权归原权利方。
