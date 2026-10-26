#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] && set -a && . ./.env && set +a
mkdir -p backups
stamp=$(date +%F-%H%M%S)

docker compose exec -T db sh -c 'exec mysqldump -uroot -p"$MARIADB_ROOT_PASSWORD" sa' > "backups/db-$stamp.sql"
docker compose run --rm --no-deps --entrypoint tar \
  -v "$PWD/backups":/backup gmsv czf "/backup/char-$stamp.tgz" -C /app/saac/char .

echo "已备份："
ls -lh "backups/db-$stamp.sql" "backups/char-$stamp.tgz"
echo "恢复到新机器时用：./scripts/restore.sh backups/db-$stamp.sql backups/char-$stamp.tgz"
