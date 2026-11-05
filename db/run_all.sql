-- =============================================================================
-- run_all.sql  (user ZOO @ FREEPDB1)
-- Chạy theo thứ tự: reset → common → animals → staff → food/health → tickets
-- Cuối: in USER_ERRORS + đếm số dòng mỗi bảng
-- Gọi: sqlplus ZOO/...@FREEPDB1 @/db/run_all.sql
-- =============================================================================

SET ECHO OFF
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 200
SET DEFINE OFF
SET VERIFY OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

ALTER SESSION SET NLS_LANGUAGE = 'AMERICAN';
ALTER SESSION SET NLS_TERRITORY = 'AMERICA';
ALTER SESSION SET NLS_LENGTH_SEMANTICS = 'CHAR';

PROMPT ################################################################
PROMPT # ZOO — NẠP TOÀN BỘ SCHEMA
PROMPT ################################################################

PROMPT >>> 01_reset
@@01_reset.sql

PROMPT >>> 05_common
@@05_common.sql

PROMPT >>> 10_animals
@@10_animals.sql

PROMPT >>> 20_staff
@@20_staff.sql

PROMPT >>> 30_food_health
@@30_food_health.sql

PROMPT >>> 40_tickets
@@40_tickets.sql

PROMPT >>> Sinh audit_logs ≥ 5 dòng (đổi chuồng / trạng thái)
BEGIN
  sp_move_animal(12, 5);
  sp_move_animal(12, 6);
  sp_move_animal(13, 5);
  sp_move_animal(13, 6);
  UPDATE animals SET status = 'SICK'    WHERE id = 2;
  UPDATE animals SET status = 'HEALTHY' WHERE id = 2;
END;
/

COMMIT;

PROMPT ################################################################
PROMPT # LỖI BIÊN DỊCH (user_errors) — phải rỗng
PROMPT ################################################################
COLUMN name FORMAT A30
COLUMN type FORMAT A15
COLUMN text FORMAT A80
SELECT name, type, sequence, line, position, text
  FROM user_errors
 ORDER BY name, sequence;

SELECT COUNT(*) AS error_count FROM user_errors;

PROMPT ################################################################
PROMPT # ĐỐI TƯỢNG INVALID
PROMPT ################################################################
SELECT object_type, object_name, status
  FROM user_objects
 WHERE status <> 'VALID'
 ORDER BY object_type, object_name;

PROMPT ################################################################
PROMPT # ĐẾM SỐ DÒNG MỖI BẢNG (mỗi bảng phải ≥ 5)
PROMPT ################################################################
DECLARE
  v_cnt NUMBER;
  v_bad NUMBER := 0;
BEGIN
  FOR r IN (SELECT table_name FROM user_tables ORDER BY table_name) LOOP
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||r.table_name INTO v_cnt;
    DBMS_OUTPUT.PUT_LINE(RPAD(r.table_name,30)||' = '||LPAD(v_cnt,5));
    IF v_cnt < 5 THEN
      DBMS_OUTPUT.PUT_LINE('  !! CẢNH BÁO: < 5 dòng');
      v_bad := v_bad + 1;
    END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Số bảng < 5 dòng: '||v_bad);
END;
/

PROMPT ################################################################
PROMPT # TABLESPACE CỦA BẢNG / INDEX (phải = ZOO_DATA)
PROMPT ################################################################
SELECT table_name, tablespace_name FROM user_tables ORDER BY 1;
SELECT index_name, table_name, tablespace_name
  FROM user_indexes
 WHERE index_type != 'LOB'
 ORDER BY 1;

PROMPT ################################################################
PROMPT # run_all.sql XONG
PROMPT ################################################################
EXIT;
