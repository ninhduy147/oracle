-- =============================================================================
-- 20_staff.sql  (user ZOO) — Module B: nhân sự
-- positions, employees, assignments, app_accounts + view/proc/trigger + data
-- =============================================================================

PROMPT === [20] Bảng positions / employees / assignments / app_accounts ===

CREATE TABLE positions (
  id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        VARCHAR2(100) NOT NULL,
  base_salary NUMBER(12,2)  DEFAULT 0 NOT NULL,
  CONSTRAINT uk_positions_name UNIQUE (name),
  CONSTRAINT ck_positions_salary CHECK (base_salary >= 0)
) TABLESPACE ZOO_DATA;

CREATE TABLE employees (
  id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name   VARCHAR2(150) NOT NULL,
  gender      VARCHAR2(1),
  birth_date  DATE,
  phone       VARCHAR2(20),
  email       VARCHAR2(150),
  address     VARCHAR2(300),
  hire_date   DATE DEFAULT SYSDATE,
  position_id NUMBER NOT NULL,
  zone_id     NUMBER,
  status      VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL,
  CONSTRAINT fk_employees_position FOREIGN KEY (position_id) REFERENCES positions(id),
  CONSTRAINT fk_employees_zone     FOREIGN KEY (zone_id)     REFERENCES zones(id),
  CONSTRAINT uk_employees_phone UNIQUE (phone),
  CONSTRAINT uk_employees_email UNIQUE (email),
  CONSTRAINT ck_employees_gender CHECK (gender IS NULL OR gender IN ('M','F')),
  CONSTRAINT ck_employees_status CHECK (status IN ('ACTIVE','RESIGNED'))
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_employees_position_id ON employees (position_id) TABLESPACE ZOO_DATA;
CREATE INDEX idx_employees_zone_id     ON employees (zone_id)     TABLESPACE ZOO_DATA;

CREATE TABLE assignments (
  id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  employee_id  NUMBER NOT NULL,
  enclosure_id NUMBER NOT NULL,
  start_date   DATE   NOT NULL,
  end_date     DATE,
  shift        VARCHAR2(20) NOT NULL,
  CONSTRAINT fk_assignments_employee  FOREIGN KEY (employee_id)  REFERENCES employees(id),
  CONSTRAINT fk_assignments_enclosure FOREIGN KEY (enclosure_id) REFERENCES enclosures(id),
  CONSTRAINT ck_assignments_dates CHECK (end_date IS NULL OR end_date >= start_date),
  CONSTRAINT ck_assignments_shift CHECK (shift IN ('MORNING','AFTERNOON','NIGHT'))
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_assignments_employee_id  ON assignments (employee_id)  TABLESPACE ZOO_DATA;
CREATE INDEX idx_assignments_enclosure_id ON assignments (enclosure_id) TABLESPACE ZOO_DATA;
CREATE TABLE app_accounts (
  id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  username      VARCHAR2(50)  NOT NULL,
  password_hash VARCHAR2(100) NOT NULL,
  role          VARCHAR2(20)  NOT NULL,
  employee_id   NUMBER,
  CONSTRAINT uk_app_accounts_username UNIQUE (username),
  CONSTRAINT uk_app_accounts_employee UNIQUE (employee_id),
  CONSTRAINT fk_app_accounts_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT ck_app_accounts_role CHECK (role IN ('MANAGER','VET','KEEPER','CASHIER'))
) TABLESPACE ZOO_DATA;

PROMPT === [20] Views ===

CREATE OR REPLACE VIEW v_employee_details AS
SELECT e.id AS employee_id,
       e.full_name,
       e.gender,
       e.phone,
       e.email,
       e.hire_date,
       e.status,
       p.id AS position_id,
       p.name AS position_name,
       p.base_salary,
       z.id AS zone_id,
       z.name AS zone_name,
       a.username AS app_username,
       a.role AS app_role
  FROM employees e
  JOIN positions p ON p.id = e.position_id
  LEFT JOIN zones z ON z.id = e.zone_id
  LEFT JOIN app_accounts a ON a.employee_id = e.id;

CREATE OR REPLACE VIEW v_current_assignments AS
SELECT asg.id AS assignment_id,
       e.id AS employee_id,
       e.full_name,
       p.name AS position_name,
       enc.id AS enclosure_id,
       enc.name AS enclosure_name,
       z.name AS zone_name,
       asg.start_date,
       asg.end_date,
       asg.shift
  FROM assignments asg
  JOIN employees e   ON e.id = asg.employee_id
  JOIN positions p   ON p.id = e.position_id
  JOIN enclosures enc ON enc.id = asg.enclosure_id
  JOIN zones z       ON z.id = enc.zone_id
 WHERE asg.end_date IS NULL OR asg.end_date >= TRUNC(SYSDATE);

PROMPT === [20] Trigger trg_assignments_keeper ===
-- Chỉ Zookeeper được phân công chuồng

CREATE OR REPLACE TRIGGER trg_assignments_keeper
  BEFORE INSERT OR UPDATE OF employee_id ON assignments
  FOR EACH ROW
DECLARE
  v_pos positions.name%TYPE;
BEGIN
  SELECT p.name INTO v_pos
    FROM employees e
    JOIN positions p ON p.id = e.position_id
   WHERE e.id = :NEW.employee_id;

  IF v_pos <> 'Zookeeper' THEN
    RAISE_APPLICATION_ERROR(-20020,
      'Chỉ nhân viên chức danh Zookeeper mới được phân công chuồng (hiện tại: '||v_pos||')');
  END IF;
END;
/

PROMPT === [20] Procedures sp_assign_employee / sp_resign_employee ===

CREATE OR REPLACE PROCEDURE sp_assign_employee(
  p_employee_id  IN NUMBER,
  p_enclosure_id IN NUMBER,
  p_start        IN DATE,
  p_end          IN DATE,
  p_shift        IN VARCHAR2
) IS
  v_status employees.status%TYPE;
  v_cnt    NUMBER;
BEGIN
  SELECT status INTO v_status
    FROM employees WHERE id = p_employee_id FOR UPDATE;

  IF v_status <> 'ACTIVE' THEN
    RAISE_APPLICATION_ERROR(-20021, 'Nhân viên không còn đang làm việc');
  END IF;

  IF p_end IS NOT NULL AND p_end < p_start THEN
    RAISE_APPLICATION_ERROR(-20022, 'Ngày kết thúc phải >= ngày bắt đầu');
  END IF;

  IF p_shift NOT IN ('MORNING','AFTERNOON','NIGHT') THEN
    RAISE_APPLICATION_ERROR(-20023, 'Ca làm không hợp lệ (MORNING|AFTERNOON|NIGHT)');
  END IF;
  SELECT COUNT(*) INTO v_cnt
    FROM assignments
   WHERE employee_id = p_employee_id
     AND shift = p_shift
     AND start_date <= NVL(p_end, DATE '9999-12-31')
     AND NVL(end_date, DATE '9999-12-31') >= p_start;

  IF v_cnt > 0 THEN
    RAISE_APPLICATION_ERROR(-20024,
      'Nhân viên đã có phân công trùng ca trong khoảng ngày này');
  END IF;

  INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
  VALUES (p_employee_id, p_enclosure_id, p_start, p_end, p_shift);
END;
/

CREATE OR REPLACE PROCEDURE sp_resign_employee(p_employee_id IN NUMBER) IS
  v_status employees.status%TYPE;
BEGIN
  SELECT status INTO v_status
    FROM employees WHERE id = p_employee_id FOR UPDATE;

  IF v_status = 'RESIGNED' THEN
    RAISE_APPLICATION_ERROR(-20025, 'Nhân viên đã nghỉ việc trước đó');
  END IF;

  UPDATE employees SET status = 'RESIGNED' WHERE id = p_employee_id;

  UPDATE assignments
     SET end_date = TRUNC(SYSDATE)
   WHERE employee_id = p_employee_id
     AND (end_date IS NULL OR end_date > TRUNC(SYSDATE));
END;
/

PROMPT === [20] Dữ liệu positions (5) ===

INSERT INTO positions (name, base_salary) VALUES ('Manager', 25000000);
INSERT INTO positions (name, base_salary) VALUES ('Veterinarian', 18000000);
INSERT INTO positions (name, base_salary) VALUES ('Zookeeper', 12000000);
INSERT INTO positions (name, base_salary) VALUES ('Cashier', 9000000);
INSERT INTO positions (name, base_salary) VALUES ('Security Guard', 8500000);

PROMPT === [20] Employees (10): ≥2 vet, ≥4 keeper, ≥2 cashier ===

INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Nguyễn Văn An', 'M', DATE '1985-04-12', '0901000001', 'an.nguyen@zoo.vn', 'Q1, TP.HCM', DATE '2015-01-10', 1, NULL, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Trần Thị Bình', 'F', DATE '1990-08-22', '0901000002', 'binh.tran@zoo.vn', 'Q3, TP.HCM', DATE '2018-03-01', 2, 1, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Lê Minh Cường', 'M', DATE '1988-11-05', '0901000003', 'cuong.le@zoo.vn', 'Thủ Đức', DATE '2017-06-15', 2, 2, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Phạm Thị Dung', 'F', DATE '1995-02-18', '0901000004', 'dung.pham@zoo.vn', 'Q7, TP.HCM', DATE '2019-09-01', 3, 1, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Hoàng Văn Em', 'M', DATE '1993-07-30', '0901000005', 'em.hoang@zoo.vn', 'Q10, TP.HCM', DATE '2020-01-20', 3, 2, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Võ Thị Hoa', 'F', DATE '1996-12-09', '0901000006', 'hoa.vo@zoo.vn', 'Bình Thạnh', DATE '2020-05-12', 3, 3, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Đặng Quốc Hùng', 'M', DATE '1994-03-25', '0901000007', 'hung.dang@zoo.vn', 'Gò Vấp', DATE '2021-02-01', 3, 4, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Bùi Thị Lan', 'F', DATE '1998-06-14', '0901000008', 'lan.bui@zoo.vn', 'Q5, TP.HCM', DATE '2021-08-08', 4, NULL, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Ngô Văn Minh', 'M', DATE '1997-09-01', '0901000009', 'minh.ngo@zoo.vn', 'Q8, TP.HCM', DATE '2022-03-15', 4, NULL, 'ACTIVE');
INSERT INTO employees (full_name, gender, birth_date, phone, email, address, hire_date, position_id, zone_id, status)
VALUES ('Lý Văn Nam', 'M', DATE '1992-01-28', '0901000010', 'nam.ly@zoo.vn', 'Tân Bình', DATE '2019-11-11', 5, 5, 'ACTIVE');

PROMPT === [20] Assignments (~9) — chỉ Zookeeper, qua INSERT (trigger kiểm tra) ===

INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (4, 1, DATE '2024-01-01', NULL, 'MORNING');
INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (4, 2, DATE '2024-01-01', NULL, 'AFTERNOON');
INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (5, 4, DATE '2024-02-01', NULL, 'MORNING');
INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (5, 5, DATE '2024-02-01', NULL, 'AFTERNOON');
INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (6, 7, DATE '2024-03-01', NULL, 'MORNING');
INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (6, 8, DATE '2024-03-01', NULL, 'AFTERNOON');
INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (7, 9, DATE '2024-04-01', NULL, 'MORNING');
INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (7, 10, DATE '2024-04-01', NULL, 'NIGHT');
INSERT INTO assignments (employee_id, enclosure_id, start_date, end_date, shift)
VALUES (5, 6, DATE '2024-05-01', NULL, 'NIGHT');

PROMPT === [20] app_accounts (5) — mật khẩu demo Zoo@123456 (bcrypt) ===
-- Hash: $2b$12$4cRHt8Tk5yUB8PhibiZAKOPzoDI2R4GpuudfCIh4wCO2DXcd1mF2q

INSERT INTO app_accounts (username, password_hash, role, employee_id)
VALUES ('manager01', '$2b$12$4cRHt8Tk5yUB8PhibiZAKOPzoDI2R4GpuudfCIh4wCO2DXcd1mF2q', 'MANAGER', 1);
INSERT INTO app_accounts (username, password_hash, role, employee_id)
VALUES ('vet01', '$2b$12$4cRHt8Tk5yUB8PhibiZAKOPzoDI2R4GpuudfCIh4wCO2DXcd1mF2q', 'VET', 2);
INSERT INTO app_accounts (username, password_hash, role, employee_id)
VALUES ('keeper01', '$2b$12$4cRHt8Tk5yUB8PhibiZAKOPzoDI2R4GpuudfCIh4wCO2DXcd1mF2q', 'KEEPER', 4);
INSERT INTO app_accounts (username, password_hash, role, employee_id)
VALUES ('keeper02', '$2b$12$4cRHt8Tk5yUB8PhibiZAKOPzoDI2R4GpuudfCIh4wCO2DXcd1mF2q', 'KEEPER', 5);
INSERT INTO app_accounts (username, password_hash, role, employee_id)
VALUES ('cashier01', '$2b$12$4cRHt8Tk5yUB8PhibiZAKOPzoDI2R4GpuudfCIh4wCO2DXcd1mF2q', 'CASHIER', 8);

PROMPT === [20] XONG ===
