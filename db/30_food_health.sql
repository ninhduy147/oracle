-- =============================================================================
-- 30_food_health.sql  (user ZOO) — Module C: thức ăn, kho, y tế
-- =============================================================================

PROMPT === [30] Bảng suppliers / foods / purchase_orders / items / feeding / medical ===

CREATE TABLE suppliers (
  id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name    VARCHAR2(150) NOT NULL,
  phone   VARCHAR2(20),
  address VARCHAR2(300)
) TABLESPACE ZOO_DATA;

CREATE TABLE foods (
  id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name       VARCHAR2(100) NOT NULL,
  category   VARCHAR2(20)  NOT NULL,
  unit       VARCHAR2(20)  NOT NULL,
  stock_qty  NUMBER(12,2)  DEFAULT 0 NOT NULL,
  min_stock  NUMBER(12,2)  DEFAULT 10 NOT NULL,
  CONSTRAINT uk_foods_name UNIQUE (name),
  CONSTRAINT ck_foods_category CHECK (category IN ('MEAT','PLANT','MIXED')),
  CONSTRAINT ck_foods_stock CHECK (stock_qty >= 0)
) TABLESPACE ZOO_DATA;

CREATE TABLE purchase_orders (
  id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  supplier_id  NUMBER NOT NULL,
  employee_id  NUMBER NOT NULL,
  order_date   DATE DEFAULT SYSDATE NOT NULL,
  total_amount NUMBER(14,2) DEFAULT 0 NOT NULL,
  CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
  CONSTRAINT fk_po_employee FOREIGN KEY (employee_id) REFERENCES employees(id)
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_po_supplier_id ON purchase_orders (supplier_id) TABLESPACE ZOO_DATA;
CREATE INDEX idx_po_employee_id ON purchase_orders (employee_id) TABLESPACE ZOO_DATA;

CREATE TABLE purchase_order_items (
  purchase_order_id NUMBER NOT NULL,
  food_id           NUMBER NOT NULL,
  quantity          NUMBER(12,2) NOT NULL,
  unit_price        NUMBER(12,2) NOT NULL,
  expiry_date       DATE,
  CONSTRAINT pk_po_items PRIMARY KEY (purchase_order_id, food_id),
  CONSTRAINT fk_poi_po   FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_poi_food FOREIGN KEY (food_id) REFERENCES foods(id),
  CONSTRAINT ck_poi_qty   CHECK (quantity > 0),
  CONSTRAINT ck_poi_price CHECK (unit_price >= 0)
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_poi_food_id ON purchase_order_items (food_id) TABLESPACE ZOO_DATA;

CREATE TABLE feeding_logs (
  id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  animal_id   NUMBER NOT NULL,
  food_id     NUMBER NOT NULL,
  employee_id NUMBER NOT NULL,
  fed_at      TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
  quantity    NUMBER(12,2) NOT NULL,
  note        VARCHAR2(500),
  CONSTRAINT fk_feed_animal   FOREIGN KEY (animal_id)   REFERENCES animals(id),
  CONSTRAINT fk_feed_food     FOREIGN KEY (food_id)     REFERENCES foods(id),
  CONSTRAINT fk_feed_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
  CONSTRAINT ck_feed_qty CHECK (quantity > 0)
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_feed_animal_id ON feeding_logs (animal_id) TABLESPACE ZOO_DATA;
CREATE INDEX idx_feed_food_id   ON feeding_logs (food_id)   TABLESPACE ZOO_DATA;
CREATE INDEX idx_feed_emp_id    ON feeding_logs (employee_id) TABLESPACE ZOO_DATA;
CREATE INDEX idx_feed_animal_fed_at ON feeding_logs (animal_id, fed_at) TABLESPACE ZOO_DATA;

CREATE TABLE medical_records (
  id              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  animal_id       NUMBER NOT NULL,
  vet_id          NUMBER NOT NULL,
  exam_date       DATE DEFAULT SYSDATE NOT NULL,
  diagnosis       VARCHAR2(500),
  treatment       VARCHAR2(500),
  follow_up_date  DATE,
  CONSTRAINT fk_med_animal FOREIGN KEY (animal_id) REFERENCES animals(id),
  CONSTRAINT fk_med_vet    FOREIGN KEY (vet_id)    REFERENCES employees(id)
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_med_animal_id ON medical_records (animal_id) TABLESPACE ZOO_DATA;
CREATE INDEX idx_med_vet_id    ON medical_records (vet_id)    TABLESPACE ZOO_DATA;

PROMPT === [30] Views ===

CREATE OR REPLACE VIEW v_low_stock_foods AS
SELECT id AS food_id, name, category, unit, stock_qty, min_stock,
       (min_stock - stock_qty) AS shortage
  FROM foods
 WHERE stock_qty < min_stock;

CREATE OR REPLACE VIEW v_upcoming_followups AS
SELECT m.id AS medical_record_id,
       a.id AS animal_id,
       a.name AS animal_name,
       e.full_name AS vet_name,
       m.exam_date,
       m.diagnosis,
       m.follow_up_date
  FROM medical_records m
  JOIN animals a ON a.id = m.animal_id
  JOIN employees e ON e.id = m.vet_id
 WHERE m.follow_up_date IS NOT NULL
   AND m.follow_up_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 7;

CREATE OR REPLACE VIEW v_food_consumption_30d AS
SELECT f.id AS food_id,
       f.name AS food_name,
       f.unit,
       NVL(SUM(fl.quantity),0) AS qty_consumed_30d
  FROM foods f
  LEFT JOIN feeding_logs fl
    ON fl.food_id = f.id
   AND fl.fed_at >= SYSTIMESTAMP - INTERVAL '30' DAY
 GROUP BY f.id, f.name, f.unit;

PROMPT === [30] Functions ===

CREATE OR REPLACE FUNCTION fn_food_consumed(
  p_food_id IN NUMBER,
  p_from    IN TIMESTAMP,
  p_to      IN TIMESTAMP
) RETURN NUMBER IS
  v_sum NUMBER;
BEGIN
  SELECT NVL(SUM(quantity),0) INTO v_sum
    FROM feeding_logs
   WHERE food_id = p_food_id
     AND fed_at >= p_from
     AND fed_at <  p_to;
  RETURN v_sum;
END;
/

PROMPT === [30] Trigger trg_po_items_ai — nhập kho + cộng tổng tiền phiếu ===

CREATE OR REPLACE TRIGGER trg_po_items_ai
  AFTER INSERT ON purchase_order_items
  FOR EACH ROW
BEGIN
  UPDATE foods
     SET stock_qty = stock_qty + :NEW.quantity
   WHERE id = :NEW.food_id;

  UPDATE purchase_orders
     SET total_amount = total_amount + (:NEW.quantity * :NEW.unit_price)
   WHERE id = :NEW.purchase_order_id;
END;
/

PROMPT === [30] Trigger trg_medical_vet — chỉ Veterinarian được khám ===

CREATE OR REPLACE TRIGGER trg_medical_vet
  BEFORE INSERT OR UPDATE OF vet_id ON medical_records
  FOR EACH ROW
DECLARE
  v_pos positions.name%TYPE;
BEGIN
  SELECT p.name INTO v_pos
    FROM employees e
    JOIN positions p ON p.id = e.position_id
   WHERE e.id = :NEW.vet_id;

  IF v_pos <> 'Veterinarian' THEN
    RAISE_APPLICATION_ERROR(-20030,
      'Chỉ bác sĩ thú y (Veterinarian) được ghi phiếu khám (hiện tại: '||v_pos||')');
  END IF;
END;
/

PROMPT === [30] Procedure sp_feed_animal ===
-- Kiểm tra tồn kho, hợp chế độ ăn; ghi log; trừ kho. Không COMMIT.
-- -20031 động vật không hợp lệ; -20032 thiếu kho; -20033 sai chế độ ăn

CREATE OR REPLACE PROCEDURE sp_feed_animal(
  p_animal_id   IN NUMBER,
  p_food_id     IN NUMBER,
  p_employee_id IN NUMBER,
  p_quantity    IN NUMBER,
  p_note        IN VARCHAR2 DEFAULT NULL
) IS
  v_animal_status animals.status%TYPE;
  v_diet          species.diet%TYPE;
  v_category      foods.category%TYPE;
  v_stock         foods.stock_qty%TYPE;
BEGIN
  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE_APPLICATION_ERROR(-20034, 'Số lượng cho ăn phải > 0');
  END IF;

  SELECT a.status, s.diet
    INTO v_animal_status, v_diet
    FROM animals a
    JOIN species s ON s.id = a.species_id
   WHERE a.id = p_animal_id
   FOR UPDATE;

  IF v_animal_status IN ('DECEASED','TRANSFERRED') THEN
    RAISE_APPLICATION_ERROR(-20031,
      'Không thể cho ăn động vật đã chết hoặc đã chuyển đi');
  END IF;

  SELECT category, stock_qty
    INTO v_category, v_stock
    FROM foods
   WHERE id = p_food_id
   FOR UPDATE;
  IF v_diet = 'CARNIVORE' AND v_category = 'PLANT' THEN
    RAISE_APPLICATION_ERROR(-20033,
      'Thức ăn thực vật không phù hợp với động vật ăn thịt');
  END IF;
  IF v_diet = 'HERBIVORE' AND v_category = 'MEAT' THEN
    RAISE_APPLICATION_ERROR(-20033,
      'Thức ăn thịt không phù hợp với động vật ăn cỏ');
  END IF;

  IF v_stock < p_quantity THEN
    RAISE_APPLICATION_ERROR(-20032,
      'Không đủ tồn kho (còn '||v_stock||', cần '||p_quantity||')');
  END IF;

  INSERT INTO feeding_logs (animal_id, food_id, employee_id, quantity, note)
  VALUES (p_animal_id, p_food_id, p_employee_id, p_quantity, p_note);

  UPDATE foods
     SET stock_qty = stock_qty - p_quantity
   WHERE id = p_food_id;
END;
/

PROMPT === [30] Dữ liệu suppliers (5) ===

INSERT INTO suppliers (name, phone, address) VALUES ('Công ty Thịt Sạch An Khang', '0281111001', 'Bình Dương');
INSERT INTO suppliers (name, phone, address) VALUES ('Nông trại Rau Quả Đà Lạt', '0263111002', 'Đà Lạt');
INSERT INTO suppliers (name, phone, address) VALUES ('Hải sản Biển Đông', '0258111003', 'Nha Trang');
INSERT INTO suppliers (name, phone, address) VALUES ('Thức ăn hỗn hợp VietFeed', '0241111004', 'Hà Nội');
INSERT INTO suppliers (name, phone, address) VALUES ('Tre trúc Panda Care', '0281111005', 'Đồng Nai');

PROMPT === [30] Foods (9) — stock ban đầu 0, trigger bằng PO; ≥1 món dưới min_stock ===

INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Thịt bò', 'MEAT', 'kg', 0, 50);
INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Thịt gà', 'MEAT', 'kg', 0, 40);
INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Cá tươi', 'MEAT', 'kg', 0, 30);
INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Cỏ voi', 'PLANT', 'kg', 0, 100);
INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Cà rốt', 'PLANT', 'kg', 0, 40);
INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Tre trúc', 'PLANT', 'kg', 0, 60);
INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Rau hỗn hợp', 'PLANT', 'kg', 0, 30);
INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Viên hỗn hợp chim', 'MIXED', 'kg', 0, 20);
INSERT INTO foods (name, category, unit, stock_qty, min_stock) VALUES ('Tôm khô', 'MEAT', 'kg', 0, 15);

PROMPT === [30] Purchase orders (5) + ≥10 items (trigger cộng kho) ===

INSERT INTO purchase_orders (supplier_id, employee_id, order_date, total_amount)
VALUES (1, 1, TRUNC(SYSDATE)-20, 0);
INSERT INTO purchase_orders (supplier_id, employee_id, order_date, total_amount)
VALUES (2, 1, TRUNC(SYSDATE)-18, 0);
INSERT INTO purchase_orders (supplier_id, employee_id, order_date, total_amount)
VALUES (3, 1, TRUNC(SYSDATE)-15, 0);
INSERT INTO purchase_orders (supplier_id, employee_id, order_date, total_amount)
VALUES (4, 1, TRUNC(SYSDATE)-10, 0);
INSERT INTO purchase_orders (supplier_id, employee_id, order_date, total_amount)
VALUES (5, 1, TRUNC(SYSDATE)-5, 0);

-- Items (≥10)
INSERT INTO purchase_order_items VALUES (1, 1, 200, 120000, TRUNC(SYSDATE)+60);
INSERT INTO purchase_order_items VALUES (1, 2, 150, 80000,  TRUNC(SYSDATE)+45);
INSERT INTO purchase_order_items VALUES (2, 4, 500, 15000,  TRUNC(SYSDATE)+30);
INSERT INTO purchase_order_items VALUES (2, 5, 120, 20000,  TRUNC(SYSDATE)+25);
INSERT INTO purchase_order_items VALUES (2, 7, 80,  18000,  TRUNC(SYSDATE)+20);
INSERT INTO purchase_order_items VALUES (3, 3, 100, 90000,  TRUNC(SYSDATE)+15);
INSERT INTO purchase_order_items VALUES (3, 9, 40,  150000, TRUNC(SYSDATE)+20);
INSERT INTO purchase_order_items VALUES (4, 8, 60,  50000,  TRUNC(SYSDATE)+90);
INSERT INTO purchase_order_items VALUES (5, 6, 200, 35000,  TRUNC(SYSDATE)+40);
INSERT INTO purchase_order_items VALUES (4, 1, 50,  125000, TRUNC(SYSDATE)+50);
INSERT INTO purchase_order_items VALUES (5, 4, 100, 16000,  TRUNC(SYSDATE)+35);
INSERT INTO purchase_order_items VALUES (1, 3, 30,  95000,  TRUNC(SYSDATE)+12);

PROMPT === [30] Feeding logs ≥20 — gọi sp_feed_animal, dàn 7 ngày ===

BEGIN
  -- Ngày -6
  sp_feed_animal(1, 1, 4, 8,  'Cho hổ Raja');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 6 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(2, 1, 4, 6,  'Cho hổ Sita');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 6 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(3, 4, 4, 40, 'Cho voi Bông');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 6 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(7, 1, 5, 10, 'Cho sư tử Simba');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 5 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(8, 2, 5, 7,  'Cho sư tử Nala');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 5 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(10, 4, 5, 25,'Cho hươu Dài');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 5 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(5, 6, 4, 15, 'Tre cho Bao Bao');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 4 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(12, 4, 5, 12,'Cỏ cho ngựa vằn');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 4 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(15, 8, 6, 2, 'Chim hồng hạc');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 4 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(18, 2, 6, 1, 'Thịt gà cho đại bàng');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 3 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(20, 1, 7, 3, 'Thịt bò cho trăn');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 3 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(22, 3, 7, 5, 'Cá cho cá mập');
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 3 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(1, 2, 4, 5,  NULL);
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 2 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(3, 5, 4, 10, NULL);
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 2 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(11, 4, 5, 20, NULL);
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 2 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(4, 4, 4, 35, NULL);
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 1 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(13, 4, 5, 10, NULL);
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 1 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(16, 8, 6, 2, NULL);
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 1 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(21, 2, 7, 2, NULL);
  UPDATE feeding_logs SET fed_at = SYSTIMESTAMP - 1 WHERE id = (SELECT MAX(id) FROM feeding_logs);
  sp_feed_animal(22, 9, 7, 30, 'Dùng nhiều tôm khô demo low stock');
  sp_feed_animal(15, 8, 6, 1,  'Hôm nay');
END;
/

PROMPT === [30] Medical records ≥5 — ≥2 tái khám trong 7 ngày tới ===

INSERT INTO medical_records (animal_id, vet_id, exam_date, diagnosis, treatment, follow_up_date)
VALUES (6, 2, TRUNC(SYSDATE)-3, 'Rối loạn tiêu hóa nhẹ', 'Chế độ ăn lỏng + men tiêu hóa', TRUNC(SYSDATE)+2);
INSERT INTO medical_records (animal_id, vet_id, exam_date, diagnosis, treatment, follow_up_date)
VALUES (9, 3, TRUNC(SYSDATE)-10, 'Kiểm tra cách ly nhập đàn', 'Xét nghiệm máu, theo dõi', TRUNC(SYSDATE)+5);
INSERT INTO medical_records (animal_id, vet_id, exam_date, diagnosis, treatment, follow_up_date)
VALUES (1, 2, TRUNC(SYSDATE)-30, 'Khám định kỳ', 'Tiêm phòng dại', TRUNC(SYSDATE)+60);
INSERT INTO medical_records (animal_id, vet_id, exam_date, diagnosis, treatment, follow_up_date)
VALUES (3, 3, TRUNC(SYSDATE)-20, 'Nứt móng nhẹ', 'Băng bó + nghỉ ngơi', TRUNC(SYSDATE)+14);
INSERT INTO medical_records (animal_id, vet_id, exam_date, diagnosis, treatment, follow_up_date)
VALUES (22, 2, TRUNC(SYSDATE)-7, 'Da kích ứng', 'Thay nước bể + kháng sinh bôi', NULL);
INSERT INTO medical_records (animal_id, vet_id, exam_date, diagnosis, treatment, follow_up_date)
VALUES (7, 3, TRUNC(SYSDATE)-15, 'Khám răng', 'Vệ sinh răng miệng', TRUNC(SYSDATE)+3);

PROMPT === [30] XONG ===
