#!/bin/bash
set -e

DB_HOST="${DB_HOST:-db}"
DB_PASS="${DB_PASS:-sa_local_root}"
AC_PASS="${AC_PASS:-test}"

mkdir -p log lock char char_sleep data/wklog mail data/family data/fmpointdir data/fmsmemodir

# 等数据库
for i in $(seq 1 60); do
    if (echo > /dev/tcp/"$DB_HOST"/3306) >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

sed -i "s/^sql_IP .*/sql_IP ${DB_HOST}/" acserv.cf
sed -i "s/^sql_PS .*/sql_PS ${DB_PASS}/" acserv.cf
sed -i "s/^pass .*/pass ${AC_PASS}/" acserv.cf

exec ./saacjt.exe
