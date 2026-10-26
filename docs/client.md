# 客户端

客户端是 Win32 + DirectDraw 程序，必须在 Windows 虚拟机里跑。macOS 上用 Parallels / VMware Fusion / UTM 都行，装 Windows 10 或 11。

## 下载与校验

```text
https://99ds.com/downloads/windows/Stoneage2.5-Windows.rar
SHA-256 b311e21f7b63e7b5ca40c778fb74fffd02ea7daca4590a6b74d0aa2a4ef2b9a8
大小    496 MB
解压密码 无
```

校验：

```bash
shasum -a 256 Stoneage2.5-Windows.rar
```

对不上就别用，客户端 DATA 和服务端不匹配会黑屏或登录即断。

仓库根目录的 `client-2.5/` 是本地存放位置，已被 git 忽略；GitHub 单文件上限 100 MB，放不进去。

## 虚拟机设置

1. 网络选**桥接（Bridged）**。共享/NAT 下虚拟机拿不到宿主机的局域网地址。
2. 只能用 NAT 时，按虚拟机软件填宿主机网关：Parallels `10.211.55.2`，UTM 共享网络 `192.168.64.1`，VMware NAT `192.168.200.1`。
3. 显示调到 16 位色；花屏就在 `dxdiag` → 显示里禁用 DirectDraw 加速。
4. 虚拟机关掉自动更新和睡眠，客户端对切网很敏感。

## 安装

1. 把 `Stoneage2.5-Windows.rar` 拷进虚拟机再解压，得到 `SA2.5/` 和 `STW/`。
2. 去掉 `SA2.5/cax.ini` 的只读属性——STW 登录器要写它。
3. 右键 `STW/STW0.30_nosizelimit.exe` → 属性 → 兼容性：Windows 7，勾选“以管理员身份运行”。
4. 在 STW 的服务器设置里填：

   - IP：宿主机局域网地址（`./scripts/status.sh` 或 `ipconfig getifaddr en0`）
   - 端口：`9065`
   - 服务器名：我的石器
   - 部分版本的列表格式要求 IP 前加 `1`，即 `1<IP>`。

5. “激活石器”时选 `SA2.5/sa_2903.exe`。
6. 登录框输入 `player` / `123456`，或随便填（会自动注册）。

## 首次进游戏

出生 1 级、100 万石币、带虎和雷。背包里有新手装备。GM 账号是 `gm` / `gm`，GM 指令密码也是 `gm`。

## 常见问题

- **登录后立刻断开**：IP/端口/服务器名有一个不对，或客户端 DATA 与服务端不一致。先在虚拟机里 `ping <宿主 IP>`。
- **进图黑屏**：踩到服务端有、客户端没有的地图，回村再走。
- **闪退**：卸掉搜狗/QQ 输入法，默认输入法切英文。
- **“无法获得服务器 IP”**：服务器列表格式问题，改用 IP 直连并带前缀 `1`。
- **杀软报毒**：STW、`sa_2903.exe`、`sa_ext.dll` 都会被误报，整个目录加白名单。
- **花屏/颜色异常**：16 位色 + 禁用 DirectDraw；仍不行换 Win7 虚拟机。

## 版本必须配对

客户端版本必须和服务端 `gmsv/data` 同版本。换客户端就要一起换 DATA 并重编镜像，不能只换一边。2.5 的握手密钥是 `cary`，8.x 客户端配 2.5 服务端连不上。
