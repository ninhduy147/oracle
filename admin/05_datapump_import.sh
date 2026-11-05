#!/usr/bin/env bash
# Import schema ZOO -> ZOO_COPY (REMAP) de chung minh, khong pha schema that
set -euo pipefail
ORACLE_PWD="${ORACLE_PWD:-ZooOracle_Demo1}"

echo "==> Drop ZOO_COPY neu ton tai"
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
SET DEFINE OFF
BEGIN
  EXECUTE IMMEDIATE 'DROP USER ZOO_COPY CASCADE';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -1918 THEN RAISE; END IF;
END;
/
EXIT;
SQL

echo "==> Tao user ZOO_COPY + quota"
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
SET DEFINE OFF
CREATE USER ZOO_COPY IDENTIFIED BY "ZooCopy_Demo1"
  DEFAULT TABLESPACE ZOO_DATA TEMPORARY TABLESPACE ZOO_TEMP
  QUOTA UNLIMITED ON ZOO_DATA;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE TO ZOO_COPY;
EXIT;
SQL

echo "==> impdp REMAP_SCHEMA=ZOO:ZOO_COPY"
# ORA-31684 USER already exists la chap nhan duoc; khong de set -e dung script
set +e
impdp \"sys/${ORACLE_PWD}@FREEPDB1 as sysdba\" \
  DIRECTORY=dp_zoo \
  DUMPFILE=zoo_%U.dmp \
  LOGFILE=zoo_imp.log \
  REMAP_SCHEMA=ZOO:ZOO_COPY \
  REMAP_TABLESPACE=ZOO_DATA:ZOO_DATA \
  TABLE_EXISTS_ACTION=REPLACE
IMP_RC=$?
set -e
echo "impdp exit code=${IMP_RC} (1 error ORA-31684 USER exists = OK)"

echo "==> So sanh so dong ZOO vs ZOO_COPY"
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
SET DEFINE OFF SERVEROUTPUT ON
DECLARE
  v1 NUMBER; v2 NUMBER;
BEGIN
  FOR t IN (SELECT table_name FROM dba_tables WHERE owner='ZOO' ORDER BY 1) LOOP
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ZOO.'||t.table_name INTO v1;
    BEGIN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ZOO_COPY.'||t.table_name INTO v2;
    EXCEPTION WHEN OTHERS THEN v2 := -1;
    END;
    DBMS_OUTPUT.PUT_LINE(RPAD(t.table_name,28)||' ZOO='||LPAD(v1,5)||' COPY='||LPAD(v2,5)||
      CASE WHEN v1=v2 THEN ' OK' ELSE ' DIFF' END);
  END LOOP;
END;
/
EXIT;
SQL

echo "==> Don dep ZOO_COPY (tuy chon — giu de demo thi comment dong duoi)"
sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1 as sysdba" <<'SQL'
DROP USER ZOO_COPY CASCADE;
EXIT;
SQL

echo "==> Import demo xong. Log: /backup/zoo_imp.log"
