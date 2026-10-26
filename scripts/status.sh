#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v tailscale >/dev/null 2>&1; then
  echo "Tailscale: $(tailscale ip -4 2>/dev/null || echo '已安装但未登录')"
fi

docker compose ps
echo
echo "监听端口："
lsof -nP -iTCP:9065 -sTCP:LISTEN 2>/dev/null || echo "9065 未监听"
echo
echo "最近 gmsv 日志："
docker compose logs --tail=20 gmsv
