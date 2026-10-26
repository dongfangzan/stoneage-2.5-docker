#!/bin/bash
set -e

AC_HOST="${AC_HOST:-saac}"
AC_PORT="${AC_PORT:-9300}"
AC_PASS="${AC_PASS:-test}"

mkdir -p log
[ -f log/log.cf ] || cp log.cf log/log.cf

# 等账号服
for i in $(seq 1 60); do
    if (echo > /dev/tcp/"$AC_HOST"/"$AC_PORT") >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

sed -i "s/^acserv=.*/acserv=${AC_HOST}/" setup.cf
sed -i "s/^acservport=.*/acservport=${AC_PORT}/" setup.cf
sed -i "s/^acpasswd=.*/acpasswd=${AC_PASS}/" setup.cf

exec ./gmsvjt.exe -f setup.cf
