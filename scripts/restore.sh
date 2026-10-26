#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ $# -ne 2 ]; then
  echo "用法：./scripts/restore.sh <db.sql> <char.tgz>" >&2
  exit 1
fi
sql=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
chars=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")

[ -f .env ] && set -a && . ./.env && set +a

read -r -p "会覆盖当前数据库和角色存档，继续？[y/N] " ok
[ "$ok" = "y" ] || exit 0

docker compose stop gmsv saac

docker compose exec -T db sh -c 'exec mysql -uroot -p"$MARIADB_ROOT_PASSWORD" sa' < "$sql"

docker compose run --rm --no-deps --entrypoint sh -v "$chars":/backup/char.tgz gmsv -c \
  'rm -rf /app/saac/char/* && tar xzf /backup/char.tgz -C /app/saac/char'

docker compose start saac
sleep 3
docker compose start gmsv
docker compose ps
