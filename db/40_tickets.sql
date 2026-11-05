-- =============================================================================
-- 40_tickets.sql  (user ZOO) — Module D: bán vé
-- =============================================================================

PROMPT === [40] Bảng ticket_types / customers / invoices / invoice_items ===

CREATE TABLE ticket_types (
  id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  VARCHAR2(100) NOT NULL,
  price NUMBER(12,2)  DEFAULT 0 NOT NULL,
  CONSTRAINT uk_ticket_types_name UNIQUE (name),
  CONSTRAINT ck_ticket_price CHECK (price >= 0)
) TABLESPACE ZOO_DATA;

CREATE TABLE customers (
  id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name VARCHAR2(150) NOT NULL,
  phone     VARCHAR2(20),
  email     VARCHAR2(150)
) TABLESPACE ZOO_DATA;

CREATE TABLE invoices (
  id             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id    NUMBER,
  employee_id    NUMBER NOT NULL,
  issued_at      DATE DEFAULT SYSDATE NOT NULL,
  payment_method VARCHAR2(20) NOT NULL,
  total_amount   NUMBER(14,2) DEFAULT 0 NOT NULL,
  CONSTRAINT fk_inv_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_inv_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT ck_inv_pay CHECK (payment_method IN ('CASH','CARD','TRANSFER'))
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_invoices_customer_id ON invoices (customer_id) TABLESPACE ZOO_DATA;
CREATE INDEX idx_invoices_employee_id ON invoices (employee_id) TABLESPACE ZOO_DATA;
CREATE INDEX idx_invoices_issued_at   ON invoices (issued_at)   TABLESPACE ZOO_DATA;

CREATE TABLE invoice_items (
  invoice_id     NUMBER NOT NULL,
  ticket_type_id NUMBER NOT NULL,
  quantity       NUMBER NOT NULL,
  unit_price     NUMBER(12,2) NOT NULL,
  CONSTRAINT pk_invoice_items PRIMARY KEY (invoice_id, ticket_type_id),
  CONSTRAINT fk_ii_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
  CONSTRAINT fk_ii_ticket  FOREIGN KEY (ticket_type_id) REFERENCES ticket_types(id),
  CONSTRAINT ck_ii_qty   CHECK (quantity > 0),
  CONSTRAINT ck_ii_price CHECK (unit_price >= 0)
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_ii_ticket_type_id ON invoice_items (ticket_type_id) TABLESPACE ZOO_DATA;

PROMPT === [40] Views ===

CREATE OR REPLACE VIEW v_daily_revenue AS
SELECT TRUNC(issued_at) AS sale_date,
       COUNT(*) AS invoice_count,
       SUM(total_amount) AS revenue
  FROM invoices
 GROUP BY TRUNC(issued_at);

CREATE OR REPLACE VIEW v_invoice_details AS
SELECT i.id AS invoice_id,
       i.issued_at,
       i.payment_method,
       i.total_amount,
       c.full_name AS customer_name,
       e.full_name AS cashier_name,
       tt.name AS ticket_name,
       ii.quantity,
       ii.unit_price,
       (ii.quantity * ii.unit_price) AS line_amount
  FROM invoices i
  LEFT JOIN customers c ON c.id = i.customer_id
  JOIN employees e ON e.id = i.employee_id
  JOIN invoice_items ii ON ii.invoice_id = i.id
  JOIN ticket_types tt ON tt.id = ii.ticket_type_id;

PROMPT === [40] Function fn_revenue ===

CREATE OR REPLACE FUNCTION fn_revenue(p_from IN DATE, p_to IN DATE)
  RETURN NUMBER
IS
  v_sum NUMBER;
BEGIN
  SELECT NVL(SUM(total_amount),0) INTO v_sum
    FROM invoices
   WHERE issued_at >= TRUNC(p_from)
     AND issued_at <  TRUNC(p_to) + 1;
  RETURN v_sum;
END;
/

PROMPT === [40] Trigger trg_invoice_items_ai ===

CREATE OR REPLACE TRIGGER trg_invoice_items_ai
  AFTER INSERT ON invoice_items
  FOR EACH ROW
BEGIN
  UPDATE invoices
     SET total_amount = total_amount + (:NEW.quantity * :NEW.unit_price)
   WHERE id = :NEW.invoice_id;
END;
/

PROMPT === [40] Procedures sp_create_invoice / sp_add_invoice_item ===
-- Chỉ Cashier hoặc Manager đang ACTIVE được lập hóa đơn (-20040)
-- Không COMMIT trong procedure

CREATE OR REPLACE PROCEDURE sp_create_invoice(
  p_customer_id    IN NUMBER,
  p_employee_id    IN NUMBER,
  p_payment_method IN VARCHAR2,
  p_invoice_id     OUT NUMBER
) IS
  v_status employees.status%TYPE;
  v_pos    positions.name%TYPE;
BEGIN
  IF p_payment_method NOT IN ('CASH','CARD','TRANSFER') THEN
    RAISE_APPLICATION_ERROR(-20041, 'Phương thức thanh toán không hợp lệ');
  END IF;

  SELECT e.status, p.name
    INTO v_status, v_pos
    FROM employees e
    JOIN positions p ON p.id = e.position_id
   WHERE e.id = p_employee_id
   FOR UPDATE;

  IF v_status <> 'ACTIVE' THEN
    RAISE_APPLICATION_ERROR(-20040, 'Nhân viên không còn đang làm việc, không được lập hóa đơn');
  END IF;

  IF v_pos NOT IN ('Cashier','Manager') THEN
    RAISE_APPLICATION_ERROR(-20040,
      'Chỉ thu ngân hoặc quản lý được lập hóa đơn (hiện tại: '||v_pos||')');
  END IF;

  INSERT INTO invoices (customer_id, employee_id, payment_method)
  VALUES (p_customer_id, p_employee_id, p_payment_method)
  RETURNING id INTO p_invoice_id;
END;
/

CREATE OR REPLACE PROCEDURE sp_add_invoice_item(
  p_invoice_id     IN NUMBER,
  p_ticket_type_id IN NUMBER,
  p_quantity       IN NUMBER
) IS
  v_price ticket_types.price%TYPE;
BEGIN
  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE_APPLICATION_ERROR(-20042, 'Số lượng vé phải > 0');
  END IF;

  SELECT price INTO v_price
    FROM ticket_types WHERE id = p_ticket_type_id;

  INSERT INTO invoice_items (invoice_id, ticket_type_id, quantity, unit_price)
  VALUES (p_invoice_id, p_ticket_type_id, p_quantity, v_price);
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    -- Cộng dồn nếu cùng loại vé trên 1 hóa đơn
    UPDATE invoice_items
       SET quantity = quantity + p_quantity
     WHERE invoice_id = p_invoice_id
       AND ticket_type_id = p_ticket_type_id;
    UPDATE invoices
       SET total_amount = total_amount + (p_quantity * v_price)
     WHERE id = p_invoice_id;
END;
/

PROMPT === [40] Dữ liệu ticket_types (5) / customers (5) ===

INSERT INTO ticket_types (name, price) VALUES ('Adult', 150000);
INSERT INTO ticket_types (name, price) VALUES ('Child', 80000);
INSERT INTO ticket_types (name, price) VALUES ('Senior', 100000);
INSERT INTO ticket_types (name, price) VALUES ('Group', 120000);
INSERT INTO ticket_types (name, price) VALUES ('Student', 90000);

INSERT INTO customers (full_name, phone, email) VALUES ('Nguyễn Thị Mai', '0912000001', 'mai.nguyen@email.vn');
INSERT INTO customers (full_name, phone, email) VALUES ('Trần Văn Phúc', '0912000002', 'phuc.tran@email.vn');
INSERT INTO customers (full_name, phone, email) VALUES ('Lê Hoàng Anh', '0912000003', 'anh.le@email.vn');
INSERT INTO customers (full_name, phone, email) VALUES ('Phạm Minh Tuấn', '0912000004', 'tuan.pham@email.vn');
INSERT INTO customers (full_name, phone, email) VALUES ('Đỗ Thị Hạnh', '0912000005', 'hanh.do@email.vn');

PROMPT === [40] ≥20 invoices / ≥40 items qua procedure, dàn 14 ngày ===

DECLARE
  v_inv NUMBER;
  v_day NUMBER;
  v_emp NUMBER;
  v_cus NUMBER;
  v_pay VARCHAR2(20);
  v_pay_i NUMBER;
BEGIN
  FOR i IN 1..22 LOOP
    v_day := MOD(i - 1, 14);
    v_emp := CASE WHEN MOD(i,2)=0 THEN 8 ELSE 9 END;
    v_cus := MOD(i - 1, 5) + 1;
    v_pay_i := MOD(i - 1, 3);
    v_pay := CASE v_pay_i WHEN 0 THEN 'CASH' WHEN 1 THEN 'CARD' ELSE 'TRANSFER' END;

    sp_create_invoice(v_cus, v_emp, v_pay, v_inv);
    UPDATE invoices SET issued_at = TRUNC(SYSDATE) - v_day WHERE id = v_inv;
    sp_add_invoice_item(v_inv, 1, 1 + MOD(i,3));
    sp_add_invoice_item(v_inv, 2, 1 + MOD(i,2));
    IF MOD(i, 3) = 0 THEN
      sp_add_invoice_item(v_inv, 3, 1);
    END IF;
    IF MOD(i, 4) = 0 THEN
      sp_add_invoice_item(v_inv, 5, 2);
    END IF;
  END LOOP;
END;
/

PROMPT === [40] XONG ===
