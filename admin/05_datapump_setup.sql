-- 05_datapump_setup.sql — tao DIRECTORY dp_zoo -> /backup (mount host ./backup)
-- Chay: SYS @ FREEPDB1
SET SERVEROUTPUT ON
SET DEFINE OFF

CREATE OR REPLACE DIRECTORY dp_zoo AS '/backup';
GRANT READ, WRITE ON DIRECTORY dp_zoo TO ZOO;
GRANT READ, WRITE ON DIRECTORY dp_zoo TO SYSTEM;

SELECT directory_name, directory_path FROM dba_directories WHERE directory_name='DP_ZOO';
EXIT;
