-- =============================================================================
-- q00_show_schema.sql  (user ZOO)
-- Hiển thị lược đồ quan hệ + chứng minh tablespace + đếm dòng
-- =============================================================================

SET LINESIZE 200
SET PAGESIZE 200
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ========== 1. DANH SÁCH BẢNG ==========
COLUMN table_name FORMAT A30
COLUMN tablespace_name FORMAT A15
SELECT table_name, tablespace_name, num_rows
  FROM user_tables
 ORDER BY table_name;

PROMPT ========== 2. CỘT (rút gọn) ==========
COLUMN column_name FORMAT A28
COLUMN data_type FORMAT A20
COLUMN nullable FORMAT A3
SELECT table_name, column_id, column_name, data_type,
       data_length, nullable, data_default
  FROM user_tab_columns
 ORDER BY table_name, column_id;

PROMPT ========== 3. KHÓA CHÍNH ==========
COLUMN constraint_name FORMAT A30
COLUMN columns FORMAT A40
SELECT c.table_name, c.constraint_name,
       LISTAGG(cc.column_name, ', ') WITHIN GROUP (ORDER BY cc.position) AS columns
  FROM user_constraints c
  JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
 WHERE c.constraint_type = 'P'
 GROUP BY c.table_name, c.constraint_name
 ORDER BY 1;

PROMPT ========== 4. KHÓA NGOẠI (bảng → bảng cha) ==========
COLUMN child_table FORMAT A28
COLUMN child_cols FORMAT A28
COLUMN parent_table FORMAT A28
COLUMN parent_cols FORMAT A28
COLUMN delete_rule FORMAT A12
SELECT c.table_name AS child_table,
       LISTAGG(cc.column_name, ', ') WITHIN GROUP (ORDER BY cc.position) AS child_cols,
       r.table_name AS parent_table,
       LISTAGG(rc.column_name, ', ') WITHIN GROUP (ORDER BY rc.position) AS parent_cols,
       c.delete_rule,
       c.constraint_name
  FROM user_constraints c
  JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
  JOIN user_constraints r ON r.constraint_name = c.r_constraint_name
  JOIN user_cons_columns rc
    ON rc.constraint_name = r.constraint_name AND rc.position = cc.position
 WHERE c.constraint_type = 'R'
 GROUP BY c.table_name, r.table_name, c.delete_rule, c.constraint_name
 ORDER BY 1, 3;

PROMPT ========== 5. CHECK / UNIQUE ==========
COLUMN search_condition FORMAT A60
SELECT table_name, constraint_name, constraint_type, search_condition
  FROM user_constraints
 WHERE constraint_type IN ('C','U')
   AND constraint_name NOT LIKE 'SYS_%'  -- bỏ NOT NULL hệ thống nếu muốn xem hết thì xóa dòng này
 ORDER BY table_name, constraint_type, constraint_name;

PROMPT ========== 6. INDEX ==========
COLUMN index_name FORMAT A35
SELECT index_name, table_name, uniqueness, tablespace_name
  FROM user_indexes
 WHERE index_type != 'LOB'
 ORDER BY table_name, index_name;

PROMPT ========== 7. CHỨNG MINH TABLESPACE ZOO_DATA ==========
SELECT 'TABLE' AS obj_type, table_name AS obj_name, tablespace_name
  FROM user_tables
 WHERE tablespace_name <> 'ZOO_DATA'
UNION ALL
SELECT 'INDEX', index_name, tablespace_name
  FROM user_indexes
 WHERE index_type != 'LOB'
   AND tablespace_name <> 'ZOO_DATA';

PROMPT (Kết quả trên phải RỖNG — không có bảng/index ngoài ZOO_DATA)

SELECT segment_name, segment_type, tablespace_name, ROUND(bytes/1024/1024,2) AS mb
  FROM user_segments
 ORDER BY segment_type, segment_name;

PROMPT ========== 8. ĐẾM DÒNG MỌI BẢNG ==========
DECLARE
  v_cnt NUMBER;
BEGIN
  FOR r IN (SELECT table_name FROM user_tables ORDER BY table_name) LOOP
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||r.table_name INTO v_cnt;
    DBMS_OUTPUT.PUT_LINE(RPAD(r.table_name,30)||' = '||v_cnt);
    IF v_cnt < 5 THEN
      DBMS_OUTPUT.PUT_LINE('  !! CẢNH BÁO: < 5 dòng');
    END IF;
  END LOOP;
END;
/

PROMPT ========== 9. LƯỢC ĐỒ QUAN HỆ DẠNG TEXT ==========
BEGIN
  DBMS_OUTPUT.PUT_LINE('zones(id PK) 1--N enclosures(zone_id FK)');
  DBMS_OUTPUT.PUT_LINE('enclosures(id PK) 1--N animals(enclosure_id FK NULL)');
  DBMS_OUTPUT.PUT_LINE('species(id PK) 1--N animals(species_id FK)');
  DBMS_OUTPUT.PUT_LINE('positions(id PK) 1--N employees(position_id FK)');
  DBMS_OUTPUT.PUT_LINE('zones(id PK) 1--N employees(zone_id FK NULL)');
  DBMS_OUTPUT.PUT_LINE('employees N--M enclosures qua assignments');
  DBMS_OUTPUT.PUT_LINE('employees 1--1 app_accounts');
  DBMS_OUTPUT.PUT_LINE('suppliers 1--N purchase_orders; PO N--M foods qua purchase_order_items');
  DBMS_OUTPUT.PUT_LINE('animals N--M foods qua feeding_logs (+employee)');
  DBMS_OUTPUT.PUT_LINE('animals 1--N medical_records (vet → employees)');
  DBMS_OUTPUT.PUT_LINE('customers 1--N invoices; invoices N--M ticket_types qua invoice_items');
END;
/

PROMPT ========== q00 XONG ==========
