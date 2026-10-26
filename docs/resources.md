# 资源

## 仓库里有什么、没有什么

| 内容 | 在仓库 | 原因 |
| --- | --- | --- |
| 服务端源码、DATA、配置 | 有 | 约 58 MB，保证 clone 即可构建 |
| 客户端整包 | 无 | 约 496 MB，GitHub 单文件上限 100 MB |
| 8.0 服务端整包 | 无 | 12 MB 的 tar，2.5 用不到 |
| 编译产物、日志、角色存档 | 无 | 构建时生成，运行期产生 |

## 必须自己下的

### 2.5 客户端

```text
https://99ds.com/downloads/windows/Stoneage2.5-Windows.rar
大小    496 MB
SHA-256 b311e21f7b63e7b5ca40c778fb74fffd02ea7daca4590a6b74d0aa2a4ef2b9a8
```

`99ds.com` 同时发 2.5 和 8.0 客户端，宣称原版无修改。直链会随站点调整，失效就回首页找下载区：

- <https://99ds.com>
- 备用搜索：`Stoneage2.5-Windows.rar`、`石器时代 2.5 客户端`

下载后先校验 SHA-256，对不上不要用。

### 基础镜像

```bash
docker pull --platform linux/386 i386/debian:buster-slim
docker pull mariadb:10.11
```

`up.sh` 会自动拉并打本地标签。

### 服务端源码基线

- <https://github.com/chenmingbiao/stone-age>

本仓库在它之上加了 Dockerfile、DB 初始化、入口脚本、安全修复和开箱配置，并删掉了历史编译产物。

## 8.0（可选）

2.5 够用就不用看。要走 8.0 需要另外的客户端、`longzoro.dll` 和 DATA，工作量大得多。

- 8.0 客户端：`https://99ds.com/downloads/windows/Stoneage8.0-Windows.zip`（仓库根目录本地留档 `client-8.0/`）
- 8.0 服务端源码：<https://github.com/AthenaCN/StoneAge_FullEdition>
- 8.5 全量包：<https://github.com/anson1788/stoneage>

8.0 客户端要在 `data` 里把四个 BIN 改名成 `real_136.bin`、`adrn_136.bin`、`spr_115.bin`、`spradrn_115.bin` 才能配 8.0 服务端。服务端还要把 `_DEFAULT_PKEY` 换成 8.0 的密钥。2.5 的密钥是 `cary`（`gmsv/include/version.h:439`）。

## 资料与出处

| 来源 | 内容 | 门槛 |
| --- | --- | --- |
| [WeLoveSA 服务端版块](https://www.lab.welovesa.com/forumdisplay.php?fid=16) | 疯狂原始人 2.0 整包、轻石器源码、YANG 8.0 源码、螺丝端 | 注册需审核 |
| [石器时代技术论坛](https://shiqi.la/forum.php?mod=forumdisplay&fid=38) | 一键端、源码、Lua 端 | 关注册，邀请码常失效 |
| [99ds](https://99ds.com) | 2.5 / 8.0 客户端 | 无 |
| [987654321](https://www.987654321sf.com/soft/list_1_22.html) | 珍藏版服务端、完整 2.5 双端 | 付费 VIP |
| [dssz](https://www.dssz.com) | 客户端工具源码、`LONGZORO.asm` | 积分 |
| [WeLoveSA 技术史帖](https://lab.welovesa.com/viewthread.php?action=printable&tid=3536) | longzoro 血统说明 | 游客可读 |
| [疯狂原始人 2.0 整包](https://www.lab.welovesa.com/viewthread.php?tid=2514) | 2.0 服务端 + DATA + 登录器 | 注册 + 2 石币 |
| [石器俱乐部](https://www.shiqi.club/category-47.html) | 疯狂原始人 14 篇官方玩法说明 | 无 |

版本谱系、稳定性和客户端来源的完整调研在：

- [research/调研报告-石器时代与疯狂原始人私服.md](research/调研报告-石器时代与疯狂原始人私服.md)
- [research/版本稳定性调研.md](research/版本稳定性调研.md)
- [research/客户端来源与适配.md](research/客户端来源与适配.md)
- [research/疯狂原始人Online-专项调研与落地方案.md](research/疯狂原始人Online-专项调研与落地方案.md)

## 判断资源能不能用

- 只给服务端不给客户端的，大概率配不上 DATA。
- 标题写“完美/无敌/最全”、回帖只有“666”的，别当长期底座。
- 加壳的 `gmsvjt.exe` / `saacjt.exe`：断网跑，`strings` 查域名。
- 客户端版本必须和服务端 DATA 同版本；2.5 只认 `cary`。

## 版权

服务端代码源自华义/JSS 泄露代码的 longzoro 分支，上游未附许可证；客户端著作权归原权利方。本仓库和这套部署只用于学习、自用，不涉及商业运营。
