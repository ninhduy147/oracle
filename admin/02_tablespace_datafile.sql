-- =============================================================================
-- 02_tablespace_datafile.sql  — Mục 7.2 (SYS @ FREEPDB1)
-- Giới hạn Oracle 26ai Free đã kiểm chứng:
--   1) ZOO_DATA tạo mặc định BIGFILE => ORA-32771 khi ADD DATAFILE
--      => demo ADD DATAFILE trên ZOO_TEST SMALLFILE
--   2) Online MOVE DATAFILE: ORA-00439 feature not enabled
--      => chỉ demo offline (copy OS + RENAME DATAFILE)
-- An toàn: KHÔNG DROP ZOO_DATA
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET DEFINE ON
SET VERIFY OFF
COLUMN data_dir NEW_VALUE data_dir
COLUMN zoo_f NEW_VALUE zoo_f
COLUMN src_f NEW_VALUE src_f
COLUMN dst_f NEW_VALUE dst_f

PROMPT ========== 7.2.0 Thu muc datafile PDB ==========
COLUMN data_dir NEW_VALUE data_dir
SELECT REGEXP_REPLACE(file_name, '[^/]+$', '') AS data_dir
  FROM dba_data_files WHERE tablespace_name='SYSTEM' AND ROWNUM=1;
PROMPT data_dir=&data_dir

PROMPT ========== 7.2.1 Thong tin ZOO_DATA / ZOO_TEMP (da tao o Giai doan 1) ==========
SELECT tablespace_name, status, contents, bigfile
  FROM dba_tablespaces WHERE tablespace_name IN ('ZOO_DATA','ZOO_TEMP');

SELECT file_id, file_name, ROUND(bytes/1024/1024,1) mb, autoextensible,
       ROUND(maxbytes/1024/1024,1) max_mb
  FROM dba_data_files WHERE tablespace_name='ZOO_DATA'
UNION ALL
SELECT file_id, file_name, ROUND(bytes/1024/1024,1), autoextensible,
       ROUND(maxbytes/1024/1024,1)
  FROM dba_temp_files WHERE tablespace_name='ZOO_TEMP';

PROMPT ========== 7.2.2 RESIZE + AUTOEXTEND tren datafile ZOO_DATA (file duy nhat) ==========
COLUMN zoo_f NEW_VALUE zoo_f
SELECT file_name AS zoo_f FROM dba_data_files WHERE tablespace_name='ZOO_DATA' AND ROWNUM=1;

ALTER DATABASE DATAFILE '&zoo_f' RESIZE 120M;
ALTER DATABASE DATAFILE '&zoo_f' AUTOEXTEND OFF;
SELECT file_name, ROUND(bytes/1024/1024,1) mb, autoextensible FROM dba_data_files WHERE file_name='&zoo_f';

ALTER DATABASE DATAFILE '&zoo_f' AUTOEXTEND ON NEXT 10M MAXSIZE 500M;
SELECT file_name, ROUND(bytes/1024/1024,1) mb, autoextensible, ROUND(maxbytes/1024/1024,1) max_mb
  FROM dba_data_files WHERE file_name='&zoo_f';

PROMPT ========== 7.2.3 Tao ZOO_TEST SMALLFILE (2 datafile) de demo ADD/RENAME/RO/OFFLINE/DROP/MOVE ==========
DECLARE
  v_dir VARCHAR2(512);
BEGIN
  SELECT REGEXP_REPLACE(file_name, '[^/]+$', '') INTO v_dir
    FROM dba_data_files WHERE tablespace_name='SYSTEM' AND ROWNUM=1;
  FOR t IN (SELECT tablespace_name FROM dba_tablespaces
             WHERE tablespace_name IN ('ZOO_TEST','ZOO_TEST_REN')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLESPACE '||t.tablespace_name||' INCLUDING CONTENTS AND DATAFILES';
  END LOOP;
  EXECUTE IMMEDIATE
    'CREATE SMALLFILE TABLESPACE ZOO_TEST DATAFILE '''||v_dir||
    'zoo_test01.dbf'' SIZE 20M AUTOEXTEND ON NEXT 5M MAXSIZE 100M';
  DBMS_OUTPUT.PUT_LINE('Created SMALLFILE ZOO_TEST');
END;
/

PROMPT >>> ADD DATAFILE thu 2 (chi SMALLFILE moi lam duoc)
DECLARE
  v_dir VARCHAR2(512);
BEGIN
  SELECT REGEXP_REPLACE(file_name, '[^/]+$', '') INTO v_dir
    FROM dba_data_files WHERE tablespace_name='SYSTEM' AND ROWNUM=1;
  EXECUTE IMMEDIATE
    'ALTER TABLESPACE ZOO_TEST ADD DATAFILE '''||v_dir||
    'zoo_test02.dbf'' SIZE 10M AUTOEXTEND ON NEXT 5M MAXSIZE 50M';
  DBMS_OUTPUT.PUT_LINE('Added zoo_test02.dbf');
END;
/

SELECT file_id, file_name, ROUND(bytes/1024/1024,1) mb
  FROM dba_data_files WHERE tablespace_name='ZOO_TEST' ORDER BY file_id;

PROMPT >>> Bang demo (SYS so huu, tranh quota ZOO)
CREATE TABLE demo_ts_test (
  id NUMBER PRIMARY KEY,
  note VARCHAR2(50)
) TABLESPACE ZOO_TEST;
INSERT INTO demo_ts_test VALUES (1, 'seed');
COMMIT;

PROMPT ========== 7.2.4 READ ONLY / READ WRITE ==========
ALTER TABLESPACE ZOO_TEST READ ONLY;
PROMPT Expect ORA-00372 or ORA-01647 on DML:
BEGIN
  INSERT INTO demo_ts_test VALUES (2, 'fail readonly');
  COMMIT;
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
ALTER TABLESPACE ZOO_TEST READ WRITE;
INSERT INTO demo_ts_test VALUES (2, 'ok read write');
COMMIT;
SELECT * FROM demo_ts_test;

PROMPT ========== 7.2.5 OFFLINE / ONLINE ==========
ALTER TABLESPACE ZOO_TEST OFFLINE;
PROMPT Expect error selecting offline TS:
BEGIN
  FOR r IN (SELECT * FROM demo_ts_test) LOOP NULL; END LOOP;
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
ALTER TABLESPACE ZOO_TEST ONLINE;
SELECT COUNT(*) AS rows_after_online FROM demo_ts_test;

PROMPT ========== 7.2.6 RENAME tablespace ==========
ALTER TABLESPACE ZOO_TEST RENAME TO ZOO_TEST_REN;
SELECT tablespace_name, status FROM dba_tablespaces WHERE tablespace_name LIKE 'ZOO_TEST%';
ALTER TABLESPACE ZOO_TEST_REN RENAME TO ZOO_TEST;

PROMPT ========== 7.2.7 MOVE offline (copy OS + RENAME DATAFILE) ==========
PROMPT Online MOVE bi ORA-00439 tren Free; dung offline.
COLUMN src_f NEW_VALUE src_f
COLUMN dst_f NEW_VALUE dst_f
SELECT file_name AS src_f FROM dba_data_files
 WHERE tablespace_name='ZOO_TEST' AND file_name LIKE '%zoo_test01.dbf';
SELECT REGEXP_REPLACE(file_name, 'zoo_test01.dbf$', 'zoo_test01_moved.dbf') AS dst_f
  FROM dba_data_files
 WHERE tablespace_name='ZOO_TEST' AND file_name LIKE '%zoo_test01.dbf';

PROMPT BEFORE:
SELECT file_name FROM dba_data_files WHERE tablespace_name='ZOO_TEST' ORDER BY 1;

ALTER TABLESPACE ZOO_TEST OFFLINE NORMAL;

HOST cp -v &src_f &dst_f

ALTER TABLESPACE ZOO_TEST RENAME DATAFILE '&src_f' TO '&dst_f';
ALTER TABLESPACE ZOO_TEST ONLINE;

PROMPT AFTER offline move:
SELECT file_name FROM dba_data_files WHERE tablespace_name='ZOO_TEST' ORDER BY 1;
SELECT * FROM demo_ts_test;

PROMPT ========== 7.2.8 DROP ZOO_TEST (AN TOAN — khong xoa ZOO_DATA) ==========
DROP TABLE demo_ts_test PURGE;
DROP TABLESPACE ZOO_TEST INCLUDING CONTENTS AND DATAFILES;
SELECT tablespace_name FROM dba_tablespaces WHERE tablespace_name LIKE 'ZOO%';

PROMPT ========== 7.2.9 BAO CAO ==========
SELECT tablespace_name, status, contents, bigfile
  FROM dba_tablespaces
 WHERE tablespace_name IN ('ZOO_DATA','ZOO_TEMP','SYSTEM','SYSAUX','USERS','TEMP')
 ORDER BY 1;

SELECT tablespace_name, file_name, ROUND(bytes/1024/1024,1) mb, autoextensible
  FROM dba_data_files WHERE tablespace_name LIKE 'ZOO%'
UNION ALL
SELECT tablespace_name, file_name, ROUND(bytes/1024/1024,1), autoextensible
  FROM dba_temp_files WHERE tablespace_name LIKE 'ZOO%';

SELECT df.tablespace_name,
       ROUND(df.bytes/1024/1024,1) AS size_mb,
       ROUND(NVL(fs.free_mb,0),1) AS free_mb,
       ROUND(100 * NVL(fs.free_mb,0) / NULLIF(df.bytes/1024/1024,0),1) AS free_pct
  FROM (SELECT tablespace_name, SUM(bytes) bytes FROM dba_data_files GROUP BY tablespace_name) df
  LEFT JOIN (SELECT tablespace_name, SUM(bytes)/1024/1024 free_mb FROM dba_free_space GROUP BY tablespace_name) fs
    ON fs.tablespace_name = df.tablespace_name
 WHERE df.tablespace_name = 'ZOO_DATA';

SELECT segment_name, segment_type, ROUND(bytes/1024/1024,3) AS mb
  FROM dba_segments
 WHERE owner='ZOO' AND segment_type='TABLE'
 ORDER BY bytes DESC
 FETCH FIRST 8 ROWS ONLY;

SELECT username, default_tablespace, temporary_tablespace FROM dba_users WHERE username='ZOO';
SELECT username, tablespace_name,
       CASE max_bytes WHEN -1 THEN 'UNLIMITED' ELSE TO_CHAR(ROUND(max_bytes/1024/1024,1)) END AS quota_mb
  FROM dba_ts_quotas WHERE username='ZOO';

PROMPT ========== 7.2.10 Chung minh object ZOO trong ZOO_DATA ==========
SELECT 'TABLE' typ, table_name name, tablespace_name FROM dba_tables WHERE owner='ZOO' AND tablespace_name<>'ZOO_DATA'
UNION ALL
SELECT 'INDEX', index_name, tablespace_name FROM dba_indexes WHERE owner='ZOO' AND index_type<>'LOB' AND tablespace_name<>'ZOO_DATA';
PROMPT (Ket qua tren phai RONG)

PROMPT ========== 7.2 XONG ==========
EXIT;
