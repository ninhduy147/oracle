#!/usr/bin/env bash
# Export schema ZOO bang Data Pump (chay TRONG container hoặc qua docker compose exec)
set -euo pipefail
ORACLE_PWD="${ORACLE_PWD:-ZooOracle_Demo1}"

echo "==> Setup DIRECTORY dp_zoo"
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" @/admin/05_datapump_setup.sql

echo "==> Dem dong truoc export"
sqlplus -s "ZOO/ZooApp_Demo1@FREEPDB1" <<'SQL'
SET HEADING OFF FEEDBACK OFF DEFINE OFF
SELECT 'animals='||COUNT(*) FROM animals;
SELECT 'invoices='||COUNT(*) FROM invoices;
SELECT 'foods='||COUNT(*) FROM foods;
EXIT;
SQL

rm -f /backup/zoo_01.dmp /backup/zoo_exp.log /backup/zoo_*.dmp 2>/dev/null || true

echo "==> expdp SCHEMAS=ZOO"
expdp \"sys/${ORACLE_PWD}@FREEPDB1 as sysdba\" \
  SCHEMAS=ZOO \
  DIRECTORY=dp_zoo \
  DUMPFILE=zoo_%U.dmp \
  LOGFILE=zoo_exp.log \
  REUSE_DUMPFILES=Y \
  EXCLUDE=STATISTICS

echo "==> Files trong /backup:"
ls -lh /backup/zoo_* 2>/dev/null || ls -lh /backup/
echo "==> Export xong. Log: /backup/zoo_exp.log"
