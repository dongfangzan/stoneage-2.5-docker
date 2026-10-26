# 从局域网 / 外网访问

游戏协议是裸 TCP 9065，没有 TLS，也没有 HTTP 层可以套 CDN。按使用场景选方案。

## 同一局域网（回家、同屋）

1. 宿主机执行 `./scripts/status.sh`，或 `ipconfig getifaddr en0`，拿到形如 `192.168.x.x` 的地址。
2. 客户端虚拟机网络设为桥接，登录器填 `<该地址>:9065`。
3. 手机热点/访客 Wi-Fi 常做客户端隔离，同网也不一定能通，换成主路由 Wi-Fi 试。

`SERVER_BIND` 保持默认 `0.0.0.0`。

## 外网直连：Tailscale（推荐）

不用公网 IP，不用改路由器，能穿过 CGNAT，链路是 WireGuard 加密。两端都装、登同一账号即可。

1. 宿主机装 Tailscale 并登录：

   ```bash
   brew install --cask tailscale
   tailscale up
   tailscale ip -4          # 记下 100.x.y.z
   ```

2. 跑客户端的 Windows 机器装 Tailscale 并登录同一账号。如果客户端在宿主机的虚拟机里，**在虚拟机内装**；桥接网络下虚拟机看不到宿主机自己的 tailnet 路由。
3. 登录器填 `100.x.y.z:9065`。
4. 验证：`tailscale status` 两台设备都是 `active`；客户端机器 `ping 100.x.y.z`。

注意：

- 免费版设备数够个人用，但别把整台 Mac 的磁盘共享一起开了。
- Tailscale 会给每台设备一个稳定 IP，重装/换机会变，可用 MagicDNS 设备名代替。
- 只在 tailnet 内可见，公网扫不到 9065。

## 外网直连：路由器端口映射

需要公网 IPv4 且不是 CGNAT。判断方法：路由器 WAN 口 IP 与 `curl ifconfig.me` 的结果一致才可用。

1. 给宿主机设 DHCP 静态保留，避免 IP 变化。
2. 路由器加端口映射：外部 TCP `9065` → 宿主机内网 IP `9065`。
3. 客户端填 `<公网 IP>:9065`。
4. 公网 IP 会变就上 DDNS（路由器自带或 `ddns-go`），用域名代替。
5. 从手机 4G/5G（关 Wi-Fi）测一次，能进才算通。

macOS 自带防火墙如果开着，允许 OrbStack/Docker 接收入站连接。

## 临时公网端口（无需账号）

只想临时从外面连一下、不装 VPN 时用。适合短时间使用，不适合长期开服。

### pinggy（已验证可用，60 分钟）

```bash
./scripts/tunnel.sh pinggy
```

等价于：

```bash
ssh -p 443 -R0:127.0.0.1:9065 tcp@a.pinggy.io
```

输出里有一行 `tcp://xxxx.run.pinggy-free.link:端口`，客户端填其中的主机和端口。走 443，普通网络一般能通。60 分钟到期重连会换地址。

### bore（公共服务器，可能被网络拦）

```bash
brew install bore-cli
./scripts/tunnel.sh bore
```

输出形如 `listening at bore.pub:41234`。本机网络实测 `bore.pub:7835` 超时，pinggy 正常，优先用前者。

两种方式的共同注意点：公网端口公开可见，跑之前至少改掉 GM 口令；断开重连会换端口；只转发游戏端口，不要顺手把数据库也发出去。

## 外网直连：frp + 一台 VPS

没有公网 IP、又不想用 Tailscale 时用这个，需要一台有公网 IP 的 VPS 和域名（可选）。

VPS 上 `frps.toml`：

```toml
bindPort = 7000
auth.method = "token"
auth.token = "换成一串长随机值"
```

宿主机 `frpc.toml`：

```toml
serverAddr = "VPS_IP"
serverPort = 7000
auth.method = "token"
auth.token = "同一串长随机值"

[[proxies]]
name = "stoneage"
type = "tcp"
localIP = "127.0.0.1"
localPort = 9065
remotePort = 9065
```

客户端连 `VPS_IP:9065`。VPS 安全组只放 7000 和 9065，`frps` 用 systemd 常驻。

## Cloudflare Tunnel

`cloudflared tunnel --url tcp://localhost:9065` 会给一个域名，但裸 TCP 需要客户端侧也装 `cloudflared access tcp` 做本地转发，登录器不能直接填域名。能用，但比 Tailscale 多一步，不优先。

## 公网暴露前必做

- 改 `.env` 的 `DB_ROOT_PASSWORD` 和 `AC_PASS`。
- 改 GM 口令：`server-2.5/gmsv/data/gmset.txt` 的 `gm gm 3`，以及数据库 `user_table` 里 `gm` 的密码。
- 决定是否关自动注册：`server-2.5/saac/acserv.cf` 改 `AutoReg 0`，之后用 SQL 手动建号。
- 只发布 9065；`saac` 的 9300 和 MariaDB 的 3306 不要映射到宿主机。
- 定期 `./scripts/backup.sh`，公网环境至少每天一次。

细节见 [security.md](security.md)。
