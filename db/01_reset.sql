-- =============================================================================
-- 01_reset.sql
-- Chạy bằng: user ZOO trên FREEPDB1
-- Làm gì: xóa sạch mọi đối tượng schema ZOO để dựng lại từ đầu
-- Vì sao: cho phép db-reset / chạy lại run_all không bị ORA-00955
-- Kết quả mong đợi: USER_OBJECTS trống (hoặc chỉ còn recyclebin đã purge)
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
PROMPT === [01] Drop toàn bộ đối tượng schema ZOO ===

BEGIN
  -- Job DBMS_SCHEDULER (nếu có)
  FOR j IN (SELECT job_name FROM user_scheduler_jobs) LOOP
    BEGIN
      DBMS_SCHEDULER.DROP_JOB(j.job_name, FORCE => TRUE);
      DBMS_OUTPUT.PUT_LINE('Dropped job '||j.job_name);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Skip job '||j.job_name||': '||SQLERRM);
    END;
  END LOOP;
  FOR v IN (SELECT view_name FROM user_views) LOOP
    EXECUTE IMMEDIATE 'DROP VIEW '||v.view_name;
  END LOOP;
  FOR t IN (SELECT trigger_name FROM user_triggers) LOOP
    EXECUTE IMMEDIATE 'DROP TRIGGER '||t.trigger_name;
  END LOOP;
  FOR p IN (
    SELECT object_name, object_type
      FROM user_objects
     WHERE object_type IN ('PROCEDURE','FUNCTION','PACKAGE','PACKAGE BODY','TYPE','TYPE BODY')
     ORDER BY DECODE(object_type,'PACKAGE BODY',1,'TYPE BODY',1,'PACKAGE',2,'TYPE',2,'PROCEDURE',3,'FUNCTION',3)
  ) LOOP
    BEGIN
      IF p.object_type = 'PACKAGE BODY' THEN
        EXECUTE IMMEDIATE 'DROP PACKAGE BODY '||p.object_name;
      ELSIF p.object_type = 'TYPE BODY' THEN
        EXECUTE IMMEDIATE 'DROP TYPE BODY '||p.object_name;
      ELSE
        EXECUTE IMMEDIATE 'DROP '||p.object_type||' '||p.object_name;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Skip '||p.object_type||' '||p.object_name||': '||SQLERRM);
    END;
  END LOOP;
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||t.table_name||' CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('Dropped table '||t.table_name);
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE '||s.sequence_name;
  END LOOP;
  FOR i IN (SELECT index_name FROM user_indexes WHERE index_type != 'LOB') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP INDEX '||i.index_name;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  EXECUTE IMMEDIATE 'PURGE RECYCLEBIN';
  DBMS_OUTPUT.PUT_LINE('=== [01] Reset xong ===');
END;
/
