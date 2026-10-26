#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! docker info >/dev/null 2>&1; then
  echo "Docker 没在运行，先启动 Docker Desktop / OrbStack。" >&2
  exit 1
fi

[ -f .env ] && set -a && . ./.env && set +a
PORT="${SERVER_PORT:-9065}"

# 当前网络下 BuildKit 取 Docker Hub token 会超时，用本地标签 + 旧版 builder
ensure_image() {
  local src="$1" dst="$2"
  docker image inspect "$dst" >/dev/null 2>&1 && return
  docker image inspect "$src" >/dev/null 2>&1 || docker pull --platform linux/386 "$src"
  docker tag "$src" "$dst"
}
ensure_image i386/debian:buster-slim stoneage-base:i386
ensure_image mariadb:10.11 stoneage-mariadb:10.11

DOCKER_BUILDKIT=0 docker build -t stoneage-25:local ./server-2.5
docker compose up -d

echo -n "等待游戏端口 $PORT "
for _ in $(seq 1 60); do
  if nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; then
    echo "就绪"
    docker compose ps
    echo
    echo "局域网地址：$(./scripts/lan-ip.sh):$PORT"
    exit 0
  fi
  echo -n "."
  sleep 1
done
echo "超时"
docker compose ps
docker compose logs --tail=40 gmsv
exit 1
