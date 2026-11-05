-- =============================================================================
-- 04_users_privileges.sql — Mục 7.4 (SYS @ FREEPDB1)
-- Profile, ROLE, user demo, GRANT/REVOKE, lock/unlock, kiểm chứng đăng nhập
-- Luu y: app web dung 1 user ZOO; cac user Oracle day chi minh hoa phan quyen CSDL
-- Mat khau demo: ZooRole_Demo1 (khong phai production)
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET DEFINE OFF

PROMPT ========== 7.4.1 PROFILE ==========
BEGIN
  FOR r IN (SELECT profile FROM dba_profiles WHERE profile IN ('PF_ZOO_STAFF','PF_ZOO_MANAGER') GROUP BY profile) LOOP
    BEGIN EXECUTE IMMEDIATE 'DROP PROFILE '||r.profile||' CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
  END LOOP;
END;
/

CREATE PROFILE pf_zoo_staff LIMIT
  FAILED_LOGIN_ATTEMPTS 3
  PASSWORD_LIFE_TIME 90
  PASSWORD_LOCK_TIME 1
  PASSWORD_REUSE_MAX 3
  PASSWORD_REUSE_TIME 30
  SESSIONS_PER_USER 3
  IDLE_TIME 30
  PASSWORD_GRACE_TIME 7;

CREATE PROFILE pf_zoo_manager LIMIT
  FAILED_LOGIN_ATTEMPTS 5
  PASSWORD_LIFE_TIME 180
  PASSWORD_LOCK_TIME 1
  PASSWORD_REUSE_MAX 5
  PASSWORD_REUSE_TIME 30
  SESSIONS_PER_USER 10
  IDLE_TIME 60
  PASSWORD_GRACE_TIME 14;

PROMPT ========== 7.4.2 ROLE (drop user demo truoc neu con sot) ==========
BEGIN
  FOR u IN (SELECT username FROM dba_users
             WHERE username IN ('ZOO_MANAGER','ZOO_VET','ZOO_KEEPER','ZOO_CASHIER','ZOO_TEMP_DEMO')) LOOP
    EXECUTE IMMEDIATE 'DROP USER '||u.username||' CASCADE';
  END LOOP;
  FOR r IN (SELECT role FROM dba_roles WHERE role IN ('R_MANAGER','R_VET','R_KEEPER','R_CASHIER')) LOOP
    EXECUTE IMMEDIATE 'DROP ROLE '||r.role;
  END LOOP;
END;
/

CREATE ROLE r_manager;
CREATE ROLE r_vet;
CREATE ROLE r_keeper;
CREATE ROLE r_cashier;

GRANT CREATE SESSION TO r_manager, r_vet, r_keeper, r_cashier;

PROMPT >>> Quyen doi tuong khac nhau that su
-- Manager: doc rong + execute procedure nghiep vu
BEGIN
  FOR t IN (SELECT table_name FROM dba_tables WHERE owner='ZOO') LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON ZOO.'||t.table_name||' TO r_manager';
  END LOOP;
  FOR v IN (SELECT view_name FROM dba_views WHERE owner='ZOO') LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON ZOO.'||v.view_name||' TO r_manager';
  END LOOP;
END;
/
GRANT EXECUTE ON ZOO.sp_move_animal TO r_manager;
GRANT EXECUTE ON ZOO.sp_assign_employee TO r_manager;
GRANT EXECUTE ON ZOO.sp_resign_employee TO r_manager;
GRANT EXECUTE ON ZOO.sp_feed_animal TO r_manager;
GRANT EXECUTE ON ZOO.sp_create_invoice TO r_manager;
GRANT EXECUTE ON ZOO.sp_add_invoice_item TO r_manager;
GRANT SELECT ON ZOO.audit_logs TO r_manager;

-- Vet: animal + medical + species; KHONG invoice
GRANT SELECT ON ZOO.animals TO r_vet;
GRANT SELECT ON ZOO.species TO r_vet;
GRANT SELECT ON ZOO.enclosures TO r_vet;
GRANT SELECT ON ZOO.zones TO r_vet;
GRANT SELECT ON ZOO.medical_records TO r_vet;
GRANT SELECT ON ZOO.v_animal_details TO r_vet;
GRANT SELECT ON ZOO.v_upcoming_followups TO r_vet;
GRANT INSERT, UPDATE ON ZOO.medical_records TO r_vet;

-- Keeper: animal/enclosure/food/feeding; KHONG medical_records
GRANT SELECT ON ZOO.animals TO r_keeper;
GRANT SELECT ON ZOO.species TO r_keeper;
GRANT SELECT ON ZOO.enclosures TO r_keeper;
GRANT SELECT ON ZOO.zones TO r_keeper;
GRANT SELECT ON ZOO.foods TO r_keeper;
GRANT SELECT ON ZOO.feeding_logs TO r_keeper;
GRANT SELECT ON ZOO.v_animal_details TO r_keeper;
GRANT SELECT ON ZOO.v_enclosure_occupancy TO r_keeper;
GRANT SELECT ON ZOO.v_low_stock_foods TO r_keeper;
GRANT EXECUTE ON ZOO.sp_feed_animal TO r_keeper;
GRANT EXECUTE ON ZOO.sp_move_animal TO r_keeper;

-- Cashier: ticket/invoice; KHONG medical_records
GRANT SELECT ON ZOO.ticket_types TO r_cashier;
GRANT SELECT ON ZOO.customers TO r_cashier;
GRANT SELECT ON ZOO.invoices TO r_cashier;
GRANT SELECT ON ZOO.invoice_items TO r_cashier;
GRANT SELECT ON ZOO.v_daily_revenue TO r_cashier;
GRANT SELECT ON ZOO.v_invoice_details TO r_cashier;
GRANT EXECUTE ON ZOO.sp_create_invoice TO r_cashier;
GRANT EXECUTE ON ZOO.sp_add_invoice_item TO r_cashier;
GRANT INSERT, UPDATE ON ZOO.customers TO r_cashier;

PROMPT ========== 7.4.3 USER demo ==========
BEGIN
  FOR u IN (SELECT username FROM dba_users
             WHERE username IN ('ZOO_MANAGER','ZOO_VET','ZOO_KEEPER','ZOO_CASHIER','ZOO_TEMP_DEMO')) LOOP
    EXECUTE IMMEDIATE 'DROP USER '||u.username||' CASCADE';
  END LOOP;
END;
/

CREATE USER zoo_manager IDENTIFIED BY "ZooRole_Demo1"
  DEFAULT TABLESPACE ZOO_DATA TEMPORARY TABLESPACE ZOO_TEMP
  PROFILE pf_zoo_manager QUOTA 50M ON ZOO_DATA ACCOUNT UNLOCK;
CREATE USER zoo_vet IDENTIFIED BY "ZooRole_Demo1"
  DEFAULT TABLESPACE ZOO_DATA TEMPORARY TABLESPACE ZOO_TEMP
  PROFILE pf_zoo_staff QUOTA 20M ON ZOO_DATA ACCOUNT UNLOCK;
CREATE USER zoo_keeper IDENTIFIED BY "ZooRole_Demo1"
  DEFAULT TABLESPACE ZOO_DATA TEMPORARY TABLESPACE ZOO_TEMP
  PROFILE pf_zoo_staff QUOTA 20M ON ZOO_DATA ACCOUNT UNLOCK;
CREATE USER zoo_cashier IDENTIFIED BY "ZooRole_Demo1"
  DEFAULT TABLESPACE ZOO_DATA TEMPORARY TABLESPACE ZOO_TEMP
  PROFILE pf_zoo_staff QUOTA 20M ON ZOO_DATA ACCOUNT UNLOCK;

GRANT r_manager TO zoo_manager;
GRANT r_vet TO zoo_vet;
GRANT r_keeper TO zoo_keeper;
GRANT r_cashier TO zoo_cashier;

PROMPT ========== 7.4.4 Minh hoa GRANT/REVOKE / ADMIN OPTION / LOCK ==========
CREATE USER zoo_temp_demo IDENTIFIED BY "ZooRole_Demo1"
  DEFAULT TABLESPACE ZOO_DATA TEMPORARY TABLESPACE ZOO_TEMP
  PROFILE pf_zoo_staff QUOTA 10M ON ZOO_DATA;
GRANT CREATE SESSION TO zoo_temp_demo;
GRANT SELECT ON ZOO.animals TO zoo_temp_demo WITH GRANT OPTION;
GRANT r_cashier TO zoo_manager WITH ADMIN OPTION;

PROMPT >>> REVOKE vi du
REVOKE SELECT ON ZOO.animals FROM zoo_temp_demo;

PROMPT >>> ACCOUNT LOCK / UNLOCK
ALTER USER zoo_temp_demo ACCOUNT LOCK;
ALTER USER zoo_temp_demo ACCOUNT UNLOCK;

PROMPT >>> Doi mat khau + het han (PASSWORD EXPIRE)
ALTER USER zoo_temp_demo IDENTIFIED BY "ZooRole_Demo2";
ALTER USER zoo_temp_demo PASSWORD EXPIRE;

PROMPT >>> Doi quota
ALTER USER zoo_cashier QUOTA 30M ON ZOO_DATA;

PROMPT >>> Xoa user tam
DROP USER zoo_temp_demo CASCADE;

PROMPT ========== 7.4.5 Truy van catalog ==========
SELECT grantee, granted_role, admin_option FROM dba_role_privs
 WHERE grantee LIKE 'ZOO_%' ORDER BY 1,2;

SELECT grantee, privilege FROM dba_sys_privs
 WHERE grantee IN ('R_MANAGER','R_VET','R_KEEPER','R_CASHIER') ORDER BY 1;

SELECT grantee, table_name, privilege FROM dba_tab_privs
 WHERE owner='ZOO' AND grantee IN ('R_CASHIER','R_VET','R_KEEPER')
   AND table_name IN ('MEDICAL_RECORDS','INVOICES','ANIMALS','FOODS')
 ORDER BY 1,2,3;

SELECT profile, resource_name, limit FROM dba_profiles
 WHERE profile IN ('PF_ZOO_STAFF','PF_ZOO_MANAGER')
   AND resource_type='PASSWORD'
 ORDER BY 1,2;

SELECT username, profile, account_status, default_tablespace FROM dba_users
 WHERE username LIKE 'ZOO_%' ORDER BY 1;

PROMPT ========== 7.4.6 Kiem chung dang nhap that (CONNECT) ==========
PROMPT >>> zoo_vet SELECT medical_records (OK)
CONNECT zoo_vet/"ZooRole_Demo1"@FREEPDB1
SET DEFINE OFF
SELECT COUNT(*) AS vet_med_ok FROM zoo.medical_records;

PROMPT >>> zoo_cashier SELECT medical_records (expect ORA-00942)
CONNECT zoo_cashier/"ZooRole_Demo1"@FREEPDB1
SET DEFINE OFF
SET SERVEROUTPUT ON
BEGIN
  EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM zoo.medical_records';
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

PROMPT >>> zoo_cashier SELECT invoices (OK)
SELECT COUNT(*) AS cashier_inv_ok FROM zoo.invoices;

PROMPT >>> zoo_keeper SELECT medical_records (expect ORA-00942)
CONNECT zoo_keeper/"ZooRole_Demo1"@FREEPDB1
SET DEFINE OFF
SET SERVEROUTPUT ON
BEGIN
  EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM zoo.medical_records';
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

PROMPT >>> zoo_keeper SELECT animals (OK)
SELECT COUNT(*) AS keeper_animal_ok FROM zoo.animals;

PROMPT >>> Tro lai SYS
CONNECT sys/ZooOracle_Demo1@FREEPDB1 AS SYSDBA
SET DEFINE OFF

PROMPT ========== 7.4 XONG ==========
EXIT;
