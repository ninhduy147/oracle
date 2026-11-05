#!/usr/bin/env bash
# 01_instance_lifecycle.sh — demo SHUTDOWN/STARTUP/RESTRICT that trong Docker
# Sau SHUTDOWN phai dung bequeath: sqlplus / as sysdba (khong qua listener)
set -euo pipefail
ORACLE_PWD="${ORACLE_PWD:-ZooOracle_Demo1}"

# Khi instance OPEN: co the dung TNS. Khi DOWN: bat buoc bequeath.
sql_tns() { sqlplus -s "sys/${ORACLE_PWD}@FREE as sysdba"; }
sql_local() { sqlplus -s / as sysdba; }
sql_pdb() { sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba"; }

echo "==> 7.1 lifecycle — trang thai ban dau"
sql_tns <<'SQL'
SELECT instance_name, status FROM v$instance;
SELECT name, open_mode, log_mode FROM v$database;
SHOW PDBS
EXIT;
SQL

echo ""
echo "==> [A] SHUTDOWN IMMEDIATE"
sql_tns <<'SQL'
SHUTDOWN IMMEDIATE;
EXIT;
SQL

echo "==> Container sau SHUTDOWN (thuong van Up; Oracle down):"
docker ps --filter name=zoo-oracle --format 'container={{.Names}} status={{.Status}}' 2>/dev/null || true

echo "==> [B] STARTUP NOMOUNT -> MOUNT -> OPEN (bequeath)"
sql_local <<'SQL'
STARTUP NOMOUNT;
SELECT status FROM v$instance;
ALTER DATABASE MOUNT;
SELECT status FROM v$instance;
SELECT name, open_mode FROM v$database;
ALTER DATABASE OPEN;
SELECT status FROM v$instance;
SELECT name, open_mode FROM v$database;
ALTER PLUGGABLE DATABASE ALL OPEN;
SHOW PDBS
EXIT;
SQL

echo "==> [C] SHUTDOWN ABORT + STARTUP (crash recovery tu dong)"
sql_tns <<'SQL'
SHUTDOWN ABORT;
EXIT;
SQL
sql_local <<'SQL'
STARTUP;
ALTER PLUGGABLE DATABASE ALL OPEN;
SELECT status FROM v$instance;
SELECT name, open_mode, log_mode FROM v$database;
EXIT;
SQL

echo "==> [D] RESTRICTED SESSION — ZOO bi ORA-01035"
sql_pdb <<'SQL'
ALTER SYSTEM ENABLE RESTRICTED SESSION;
EXIT;
SQL
set +e
echo "--- login ZOO ---"
sqlplus -s ZOO/ZooApp_Demo1@FREEPDB1 <<'SQL'
SELECT USER FROM dual;
EXIT;
SQL
set -e
echo "--- SYSDBA van OK; DISABLE ---"
sql_pdb <<'SQL'
SELECT USER FROM dual;
ALTER SYSTEM DISABLE RESTRICTED SESSION;
EXIT;
SQL

echo "==> [E] SHUTDOWN TRANSACTIONAL + STARTUP"
sql_tns <<'SQL'
SHUTDOWN TRANSACTIONAL;
EXIT;
SQL
sql_local <<'SQL'
STARTUP;
ALTER PLUGGABLE DATABASE ALL OPEN;
EXIT;
SQL

echo "==> [F] SHUTDOWN NORMAL + STARTUP"
sql_tns <<'SQL'
SHUTDOWN NORMAL;
EXIT;
SQL
sql_local <<'SQL'
STARTUP;
ALTER PLUGGABLE DATABASE ALL OPEN;
EXIT;
SQL

echo "==> [G] CDB OPEN READ ONLY; thu INSERT; tra READ WRITE"
sql_tns <<'SQL'
SHUTDOWN IMMEDIATE;
EXIT;
SQL
sql_local <<'SQL'
STARTUP MOUNT;
ALTER DATABASE OPEN READ ONLY;
SELECT open_mode FROM v$database;
EXIT;
SQL
set +e
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
SET SERVEROUTPUT ON DEFINE OFF
BEGIN
  EXECUTE IMMEDIATE q'[INSERT INTO ZOO.zones(name) VALUES ('x')]';
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
EXIT;
SQL
set -e
sql_local <<'SQL'
SHUTDOWN IMMEDIATE;
STARTUP;
ALTER PLUGGABLE DATABASE ALL OPEN;
SELECT open_mode FROM v$database;
SELECT name, open_mode FROM v$pdbs;
EXIT;
SQL

echo "==> 7.1 lifecycle XONG"
sql_tns <<'SQL'
SELECT status FROM v$instance;
SHOW PDBS
EXIT;
SQL
