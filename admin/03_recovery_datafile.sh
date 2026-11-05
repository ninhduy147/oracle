#!/usr/bin/env bash
# 03_recovery_datafile.sh — gia lap mat datafile ZOO_TEST + RMAN restore/recover
# Luu y Free/Docker:
#  - CONNECT RMAN toi CDB bang bequeath (/) khi PDB bi MOUNTED
#  - Khong CONFIGURE CHANNEL khi connected PDB (RMAN-07536)
set -euo pipefail
ORACLE_PWD="${ORACLE_PWD:-ZooOracle_Demo1}"

echo "==> 0) log_mode"
sqlplus -s "sys/${ORACLE_PWD}@FREE as sysdba" <<'SQL'
SELECT name, open_mode, log_mode FROM v$database;
EXIT;
SQL

echo "==> 1) Tao ZOO_TEST + bang demo"
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
SET SERVEROUTPUT ON DEFINE OFF
DECLARE
  v_dir VARCHAR2(512);
BEGIN
  SELECT REGEXP_REPLACE(file_name,'[^/]+$','') INTO v_dir
    FROM dba_data_files WHERE tablespace_name='SYSTEM' AND ROWNUM=1;
  BEGIN EXECUTE IMMEDIATE 'DROP TABLESPACE ZOO_TEST INCLUDING CONTENTS AND DATAFILES';
  EXCEPTION WHEN OTHERS THEN NULL; END;
  EXECUTE IMMEDIATE 'CREATE SMALLFILE TABLESPACE ZOO_TEST DATAFILE '''||v_dir||
    'zoo_test_rec01.dbf'' SIZE 20M AUTOEXTEND ON NEXT 5M MAXSIZE 100M';
END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE demo_recovery PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE demo_recovery (id NUMBER PRIMARY KEY, note VARCHAR2(100)) TABLESPACE ZOO_TEST;
INSERT INTO demo_recovery VALUES (1, 'before backup');
INSERT INTO demo_recovery VALUES (2, 'important row');
COMMIT;
SELECT file_id, file_name FROM dba_data_files WHERE tablespace_name='ZOO_TEST';
EXIT;
SQL

FILE_ID=$(sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 DEFINE OFF
SELECT file_id FROM dba_data_files WHERE tablespace_name='ZOO_TEST' AND ROWNUM=1;
EXIT;
SQL
)
FILE_ID=$(echo "$FILE_ID" | tr -d '[:space:]')
FILE_NAME=$(sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 DEFINE OFF
SELECT file_name FROM dba_data_files WHERE tablespace_name='ZOO_TEST' AND ROWNUM=1;
EXIT;
SQL
)
FILE_NAME=$(echo "$FILE_NAME" | tr -d '\r' | sed 's/^ *//;s/ *$//')
echo "FILE_ID=$FILE_ID FILE_NAME=$FILE_NAME"

echo "==> 2) RMAN BACKUP TABLESPACE ZOO_TEST (target PDB)"
rman target "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<RMAN
BACKUP TABLESPACE ZOO_TEST FORMAT '/backup/zoo_ts_zoo_test_%U';
EXIT;
RMAN

echo "==> 3) Insert SAU backup"
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
SET DEFINE OFF
INSERT INTO demo_recovery VALUES (3, 'after backup - needs redo');
COMMIT;
SELECT * FROM demo_recovery ORDER BY id;
EXIT;
SQL

echo "==> 4) Xoa datafile OS + checkpoint (PDB co the ve MOUNTED)"
rm -fv "$FILE_NAME"
set +e
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
ALTER SYSTEM CHECKPOINT;
SELECT * FROM demo_recovery;
EXIT;
SQL
set -e

echo "==> 5) OFFLINE (bequeath CDB + container FREEPDB1) -> RESTORE -> RECOVER -> ONLINE -> OPEN"
sqlplus -s / as sysdba <<SQL
ALTER SESSION SET CONTAINER=FREEPDB1;
ALTER DATABASE DATAFILE ${FILE_ID} OFFLINE;
EXIT;
SQL

rman target / <<RMAN
RESTORE DATAFILE ${FILE_ID};
RECOVER DATAFILE ${FILE_ID};
EXIT;
RMAN

sqlplus -s / as sysdba <<SQL
ALTER SESSION SET CONTAINER=FREEPDB1;
ALTER DATABASE DATAFILE ${FILE_ID} ONLINE;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN READ WRITE;
SELECT * FROM demo_recovery ORDER BY id;
EXIT;
SQL

echo "==> 6) Cleanup"
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
DROP TABLE demo_recovery PURGE;
DROP TABLESPACE ZOO_TEST INCLUDING CONTENTS AND DATAFILES;
EXIT;
SQL
echo "==> 7.3 XONG"
