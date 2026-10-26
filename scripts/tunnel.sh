#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] && set -a && . ./.env && set +a
PORT="${SERVER_PORT:-9065}"
PROVIDER="${1:-pinggy}"

if ! nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; then
  echo "本地 $PORT 没在监听，先 ./scripts/up.sh" >&2
  exit 1
fi

case "$PROVIDER" in
  pinggy)
    echo "临时公网地址，60 分钟后失效，Ctrl-C 结束。端口公开，先改 GM 口令。"
    echo "地址在下面的 tcp:// 一行，客户端只填主机和端口。"
    exec ssh -o StrictHostKeyChecking=no -p 443 -R0:"127.0.0.1:$PORT" tcp@a.pinggy.io
    ;;
  bore)
    command -v bore >/dev/null 2>&1 || { echo "先 brew install bore-cli" >&2; exit 1; }
    echo "临时公网地址，端口每次重连都会变。端口公开，先改 GM 口令。"
    exec bore local "$PORT" --to bore.pub
    ;;
  *)
    echo "用法：./scripts/tunnel.sh [pinggy|bore]" >&2
    exit 1
    ;;
esac
