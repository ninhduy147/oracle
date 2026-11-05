-- =============================================================================
-- 00_create_tablespace_user.sql
-- Chạy bằng: SYS AS SYSDBA trên PDB FREEPDB1
-- Làm gì: tạo tablespace ZOO_DATA (+ datafile riêng), ZOO_TEMP, user ZOO
-- Vì sao: ràng buộc cứng — toàn bộ đối tượng đề tài trong 1 user + 1 tablespace mới
-- Kết quả mong đợi: ZOO tồn tại, DEFAULT TABLESPACE = ZOO_DATA, TEMP = ZOO_TEMP
-- Mật khẩu demo ZOO = ZooApp_Demo1 (xem .env ORACLE_PASSWORD_ZOO)
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100

PROMPT === [00] Tạo ZOO_DATA / ZOO_TEMP / USER ZOO ===

DECLARE
  v_dir VARCHAR2(512);
  v_cnt NUMBER;
  v_sql VARCHAR2(4000);
BEGIN
  -- Lấy thư mục datafile hiện tại của PDB (không hard-code đường dẫn)
  SELECT REGEXP_REPLACE(file_name, '[^/]+$', '')
    INTO v_dir
    FROM dba_data_files
   WHERE tablespace_name = 'SYSTEM'
     AND ROWNUM = 1;

  DBMS_OUTPUT.PUT_LINE('Datafile directory: ' || v_dir);
  SELECT COUNT(*) INTO v_cnt FROM dba_tablespaces WHERE tablespace_name = 'ZOO_DATA';
  IF v_cnt = 0 THEN
    v_sql := 'CREATE TABLESPACE ZOO_DATA DATAFILE ''' || v_dir ||
             'zoo_data01.dbf'' SIZE 100M AUTOEXTEND ON NEXT 10M MAXSIZE 500M ' ||
             'EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO';
    EXECUTE IMMEDIATE v_sql;
    DBMS_OUTPUT.PUT_LINE('Đã tạo TABLESPACE ZOO_DATA');
  ELSE
    DBMS_OUTPUT.PUT_LINE('ZOO_DATA đã tồn tại — bỏ qua CREATE');
  END IF;
  SELECT COUNT(*) INTO v_cnt FROM dba_tablespaces WHERE tablespace_name = 'ZOO_TEMP';
  IF v_cnt = 0 THEN
    v_sql := 'CREATE TEMPORARY TABLESPACE ZOO_TEMP TEMPFILE ''' || v_dir ||
             'zoo_temp01.dbf'' SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 200M';
    EXECUTE IMMEDIATE v_sql;
    DBMS_OUTPUT.PUT_LINE('Đã tạo TEMPORARY TABLESPACE ZOO_TEMP');
  ELSE
    DBMS_OUTPUT.PUT_LINE('ZOO_TEMP đã tồn tại — bỏ qua CREATE');
  END IF;
  SELECT COUNT(*) INTO v_cnt FROM dba_users WHERE username = 'ZOO';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE
      'CREATE USER ZOO IDENTIFIED BY "ZooApp_Demo1"
         DEFAULT TABLESPACE ZOO_DATA
         TEMPORARY TABLESPACE ZOO_TEMP
         QUOTA UNLIMITED ON ZOO_DATA
         ACCOUNT UNLOCK';
    DBMS_OUTPUT.PUT_LINE('Đã tạo USER ZOO');
  ELSE
    EXECUTE IMMEDIATE 'ALTER USER ZOO DEFAULT TABLESPACE ZOO_DATA';
    EXECUTE IMMEDIATE 'ALTER USER ZOO TEMPORARY TABLESPACE ZOO_TEMP';
    EXECUTE IMMEDIATE 'ALTER USER ZOO QUOTA UNLIMITED ON ZOO_DATA';
    EXECUTE IMMEDIATE 'ALTER USER ZOO IDENTIFIED BY "ZooApp_Demo1" ACCOUNT UNLOCK';
    DBMS_OUTPUT.PUT_LINE('USER ZOO đã tồn tại — cập nhật tablespace/quota/password');
  END IF;
END;
/

PROMPT === [00] Cấp quyền tối thiểu cho ZOO ===
GRANT CREATE SESSION TO ZOO;
GRANT CREATE TABLE TO ZOO;
GRANT CREATE VIEW TO ZOO;
GRANT CREATE SEQUENCE TO ZOO;
GRANT CREATE PROCEDURE TO ZOO;
GRANT CREATE TRIGGER TO ZOO;
GRANT CREATE TYPE TO ZOO;
GRANT CREATE JOB TO ZOO;
GRANT SELECT_CATALOG_ROLE TO ZOO;

PROMPT === [00] Chứng minh ===
COLUMN username FORMAT A10
COLUMN default_tablespace FORMAT A15
COLUMN temporary_tablespace FORMAT A15
COLUMN account_status FORMAT A18
SELECT username, default_tablespace, temporary_tablespace, account_status
  FROM dba_users WHERE username = 'ZOO';

COLUMN tablespace_name FORMAT A15
COLUMN status FORMAT A10
COLUMN contents FORMAT A10
SELECT tablespace_name, status, contents, logging
  FROM dba_tablespaces
 WHERE tablespace_name IN ('ZOO_DATA', 'ZOO_TEMP');

COLUMN file_name FORMAT A70
SELECT file_name, tablespace_name, ROUND(bytes/1024/1024,1) AS size_mb, autoextensible
  FROM dba_data_files WHERE tablespace_name = 'ZOO_DATA'
UNION ALL
SELECT file_name, tablespace_name, ROUND(bytes/1024/1024,1), autoextensible
  FROM dba_temp_files WHERE tablespace_name = 'ZOO_TEMP';

PROMPT === [00] XONG ===
EXIT;
