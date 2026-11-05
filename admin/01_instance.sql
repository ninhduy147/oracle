-- =============================================================================
-- 01_instance.sql — Mục 7.1 (phan an toan, khong shutdown CDB)
-- Chay: SYSDBA. Ket noi CDB FREE truoc (sqlplus sys/...@FREE as sysdba)
-- Phan SHUTDOWN/STARTUP day du: xem 01_instance_lifecycle.sh
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET DEFINE OFF

PROMPT ========== 7.1.1 Trang thai instance / database / PDB ==========
SELECT instance_name, status, database_status, active_state, host_name FROM v$instance;
SELECT name, open_mode, log_mode, database_role FROM v$database;
SHOW PDBS

PROMPT ========== 7.1.2 Tham so (SHOW PARAMETER / V$PARAMETER) ==========
SHOW PARAMETER db_name
SHOW PARAMETER sga_target
SHOW PARAMETER pga_aggregate_target

SELECT name, value, isdefault, issys_modifiable
  FROM v$parameter
 WHERE name IN ('db_name','sga_target','pga_aggregate_target','open_cursors','processes')
 ORDER BY name;

PROMPT ========== 7.1.3 ALTER SYSTEM SET SCOPE=MEMORY (doi tam, khong ghi spfile) ==========
SHOW PARAMETER open_cursors
ALTER SYSTEM SET open_cursors=350 SCOPE=MEMORY;
SHOW PARAMETER open_cursors
ALTER SYSTEM SET open_cursors=300 SCOPE=MEMORY;
PROMPT (Da doi bang SCOPE=MEMORY — mat khi restart; SCOPE=SPFILE/BOTH de ben)

PROMPT ========== 7.1.4 PDB FREEPDB1 READ ONLY / READ WRITE ==========
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER PLUGGABLE DATABASE FREEPDB1 CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN READ ONLY;
SELECT name, open_mode FROM v$pdbs;

PROMPT Expect ORA-16000 on INSERT in READ ONLY PDB:
BEGIN
  EXECUTE IMMEDIATE 'INSERT INTO ZOO.zones(name, area_m2) VALUES (''tmp'',1)';
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

ALTER PLUGGABLE DATABASE FREEPDB1 CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN READ WRITE;
SELECT name, open_mode FROM v$pdbs;

PROMPT ========== 7.1.5 RESTRICTED SESSION ==========
ALTER SYSTEM ENABLE RESTRICTED SESSION;
SELECT logins FROM v$instance;

PROMPT Thu dang nhap ZOO (expect ORA-01035) — thuc hien o shell lifecycle
PROMPT Disable restricted:
ALTER SYSTEM DISABLE RESTRICTED SESSION;
SELECT logins FROM v$instance;

PROMPT ========== 7.1.6 Bang so sanh 4 che do SHUTDOWN (ly thuyet + demo o .sh) ==========
PROMPT MODE | Cho session? | Rollback txn? | Can recovery khi mo?
PROMPT NORMAL | Co (doi disconnect) | Co | Khong
PROMPT TRANSACTIONAL | Doi txn xong, tu choi txn moi | Co | Khong
PROMPT IMMEDIATE | Kick session | Co rollback | Khong
PROMPT ABORT | Kick ngay | Khong rollback | Co the can crash recovery

PROMPT ========== 7.1 SQL phan an toan XONG — tiep lifecycle.sh ==========
EXIT;
