-- =============================================================================
-- 10_animals.sql  (user ZOO) — Module A: động vật & chuồng trại
-- Tạo: zones, enclosures, species, animals + view/func/proc/trigger + dữ liệu
-- =============================================================================

PROMPT === [10] Bảng zones / enclosures / species / animals ===

CREATE TABLE zones (
  id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        VARCHAR2(100) NOT NULL,
  description VARCHAR2(500),
  area_m2     NUMBER(10,2),
  CONSTRAINT uk_zones_name UNIQUE (name),
  CONSTRAINT ck_zones_area CHECK (area_m2 IS NULL OR area_m2 > 0)
) TABLESPACE ZOO_DATA;

CREATE TABLE enclosures (
  id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name     VARCHAR2(100) NOT NULL,
  zone_id  NUMBER        NOT NULL,
  capacity NUMBER        NOT NULL,
  status   VARCHAR2(20)  DEFAULT 'ACTIVE' NOT NULL,
  CONSTRAINT fk_enclosures_zone FOREIGN KEY (zone_id) REFERENCES zones(id),
  CONSTRAINT ck_enclosures_capacity CHECK (capacity > 0),
  CONSTRAINT ck_enclosures_status CHECK (status IN ('ACTIVE','MAINTENANCE'))
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_enclosures_zone_id ON enclosures (zone_id) TABLESPACE ZOO_DATA;

CREATE TABLE species (
  id                  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name                VARCHAR2(100) NOT NULL,
  scientific_name     VARCHAR2(150),
  class_group         VARCHAR2(20)  NOT NULL,
  conservation_status VARCHAR2(5)   DEFAULT 'LC' NOT NULL,
  diet                VARCHAR2(20)  NOT NULL,
  CONSTRAINT ck_species_class CHECK (class_group IN ('MAMMAL','BIRD','REPTILE','AMPHIBIAN','FISH')),
  CONSTRAINT ck_species_cons  CHECK (conservation_status IN ('LC','NT','VU','EN','CR','EW')),
  CONSTRAINT ck_species_diet  CHECK (diet IN ('CARNIVORE','HERBIVORE','OMNIVORE'))
) TABLESPACE ZOO_DATA;

CREATE TABLE animals (
  id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name          VARCHAR2(100) NOT NULL,
  species_id    NUMBER        NOT NULL,
  enclosure_id  NUMBER,
  gender        VARCHAR2(1),
  birth_date    DATE,
  arrival_date  DATE DEFAULT SYSDATE NOT NULL,
  origin        VARCHAR2(200),
  weight_kg     NUMBER(8,2),
  status        VARCHAR2(20) DEFAULT 'HEALTHY' NOT NULL,
  CONSTRAINT fk_animals_species   FOREIGN KEY (species_id)   REFERENCES species(id),
  CONSTRAINT fk_animals_enclosure FOREIGN KEY (enclosure_id) REFERENCES enclosures(id),
  CONSTRAINT ck_animals_gender CHECK (gender IS NULL OR gender IN ('M','F')),
  CONSTRAINT ck_animals_weight CHECK (weight_kg IS NULL OR weight_kg > 0),
  CONSTRAINT ck_animals_status CHECK (status IN ('HEALTHY','SICK','QUARANTINE','DECEASED','TRANSFERRED')),
  CONSTRAINT ck_animals_dates  CHECK (birth_date IS NULL OR birth_date <= arrival_date)
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_animals_species_id   ON animals (species_id)   TABLESPACE ZOO_DATA;
CREATE INDEX idx_animals_enclosure_id ON animals (enclosure_id) TABLESPACE ZOO_DATA;
CREATE INDEX idx_animals_status       ON animals (status)       TABLESPACE ZOO_DATA;

PROMPT === [10] Views ===

CREATE OR REPLACE VIEW v_animal_details AS
SELECT a.id           AS animal_id,
       a.name         AS animal_name,
       a.gender,
       a.birth_date,
       a.arrival_date,
       a.weight_kg,
       a.status,
       a.origin,
       s.id           AS species_id,
       s.name         AS species_name,
       s.scientific_name,
       s.class_group,
       s.conservation_status,
       s.diet,
       e.id           AS enclosure_id,
       e.name         AS enclosure_name,
       e.status       AS enclosure_status,
       z.id           AS zone_id,
       z.name         AS zone_name
  FROM animals a
  JOIN species s    ON s.id = a.species_id
  LEFT JOIN enclosures e ON e.id = a.enclosure_id
  LEFT JOIN zones z      ON z.id = e.zone_id;

CREATE OR REPLACE VIEW v_enclosure_occupancy AS
SELECT e.id AS enclosure_id,
       e.name AS enclosure_name,
       e.capacity,
       e.status,
       z.name AS zone_name,
       COUNT(a.id) AS animal_count,
       e.capacity - COUNT(a.id) AS free_slots
  FROM enclosures e
  JOIN zones z ON z.id = e.zone_id
  LEFT JOIN animals a
    ON a.enclosure_id = e.id
   AND a.status NOT IN ('DECEASED','TRANSFERRED')
 GROUP BY e.id, e.name, e.capacity, e.status, z.name;

CREATE OR REPLACE VIEW v_animals_per_zone AS
SELECT z.id AS zone_id,
       z.name AS zone_name,
       COUNT(a.id) AS animal_count
  FROM zones z
  LEFT JOIN enclosures e ON e.zone_id = z.id
  LEFT JOIN animals a
    ON a.enclosure_id = e.id
   AND a.status NOT IN ('DECEASED','TRANSFERRED')
 GROUP BY z.id, z.name;

PROMPT === [10] Function fn_enclosure_free_slots ===

CREATE OR REPLACE FUNCTION fn_enclosure_free_slots(p_enclosure_id IN NUMBER)
  RETURN NUMBER
IS
  v_capacity NUMBER;
  v_used     NUMBER;
BEGIN
  SELECT capacity INTO v_capacity
    FROM enclosures WHERE id = p_enclosure_id;

  SELECT COUNT(*) INTO v_used
    FROM animals
   WHERE enclosure_id = p_enclosure_id
     AND status NOT IN ('DECEASED','TRANSFERRED');

  RETURN v_capacity - v_used;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20010, 'Không tìm thấy chuồng id='||p_enclosure_id);
END;
/

PROMPT === [10] Procedure sp_move_animal ===
-- Không COMMIT bên trong — caller quyết định.
-- Lỗi: -20001 chuồng bảo trì, -20002 đầy, -20004 chết/đã chuyển, -20010 không tồn tại

CREATE OR REPLACE PROCEDURE sp_move_animal(
  p_animal_id    IN NUMBER,
  p_enclosure_id IN NUMBER
) IS
  v_status       animals.status%TYPE;
  v_old_enc      animals.enclosure_id%TYPE;
  v_enc_status   enclosures.status%TYPE;
  v_free         NUMBER;
BEGIN
  SELECT status, enclosure_id
    INTO v_status, v_old_enc
    FROM animals
   WHERE id = p_animal_id
   FOR UPDATE;

  IF v_status IN ('DECEASED','TRANSFERRED') THEN
    RAISE_APPLICATION_ERROR(-20004,
      'Không thể chuyển: động vật đã chết hoặc đã chuyển đi (status='||v_status||')');
  END IF;

  SELECT status INTO v_enc_status
    FROM enclosures
   WHERE id = p_enclosure_id
   FOR UPDATE;

  IF v_enc_status = 'MAINTENANCE' THEN
    RAISE_APPLICATION_ERROR(-20001, 'Chuồng đang bảo trì, không nhận động vật');
  END IF;

  v_free := fn_enclosure_free_slots(p_enclosure_id);
  IF v_old_enc = p_enclosure_id THEN
    NULL;
  ELSIF v_free <= 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Chuồng đã đầy, không còn chỗ trống');
  END IF;

  UPDATE animals
     SET enclosure_id = p_enclosure_id
   WHERE id = p_animal_id;
END;
/

PROMPT === [10] Trigger trg_animals_audit ===

CREATE OR REPLACE TRIGGER trg_animals_audit
  AFTER UPDATE OR DELETE ON animals
  FOR EACH ROW
BEGIN
  IF DELETING THEN
    INSERT INTO audit_logs (table_name, action, record_id, details)
    VALUES ('animals', 'DELETE', :OLD.id,
            'Xóa động vật "'||:OLD.name||'", status='||:OLD.status||
            ', enclosure_id='||:OLD.enclosure_id);
  ELSIF UPDATING THEN
    IF NVL(:OLD.status,'~') <> NVL(:NEW.status,'~')
       OR NVL(:OLD.enclosure_id,-1) <> NVL(:NEW.enclosure_id,-1) THEN
      INSERT INTO audit_logs (table_name, action, record_id, details)
      VALUES ('animals', 'UPDATE', :NEW.id,
              'Đổi status '||:OLD.status||'→'||:NEW.status||
              '; enclosure '||:OLD.enclosure_id||'→'||:NEW.enclosure_id);
    END IF;
  END IF;
END;
/

PROMPT === [10] Dữ liệu mẫu zones (5) — id kỳ vọng 1..5 ===

INSERT INTO zones (name, description, area_m2) VALUES ('Khu châu Á', 'Động vật châu Á nhiệt đới', 12000);
INSERT INTO zones (name, description, area_m2) VALUES ('Khu châu Phi', 'Savanna và rừng châu Phi', 15000);
INSERT INTO zones (name, description, area_m2) VALUES ('Khu chim', 'Chuồng bay và hồ nước', 5000);
INSERT INTO zones (name, description, area_m2) VALUES ('Khu bò sát', 'Nhà kính bò sát', 3000);
INSERT INTO zones (name, description, area_m2) VALUES ('Khu thủy cung', 'Bể cá nước ngọt và mặn', 4000);

PROMPT === [10] Enclosures (11) — id 11 = MAINTENANCE để demo lỗi ===

INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng hổ Bengal', 1, 3, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng voi châu Á', 1, 4, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng gấu trúc', 1, 2, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng sư tử', 2, 4, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng hươu cao cổ', 2, 6, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng ngựa vằn', 2, 8, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng hồng hạc', 3, 20, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng đại bàng', 3, 4, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Nhà trăn', 4, 5, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Bể cá mập', 5, 6, 'ACTIVE');
INSERT INTO enclosures (name, zone_id, capacity, status) VALUES ('Chuồng bảo trì A', 1, 2, 'MAINTENANCE');

PROMPT === [10] Species (10) ===

INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Hổ Bengal', 'Panthera tigris tigris', 'MAMMAL', 'EN', 'CARNIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Voi châu Á', 'Elephas maximus', 'MAMMAL', 'EN', 'HERBIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Gấu trúc lớn', 'Ailuropoda melanoleuca', 'MAMMAL', 'VU', 'HERBIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Sư tử châu Phi', 'Panthera leo', 'MAMMAL', 'VU', 'CARNIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Hươu cao cổ', 'Giraffa camelopardalis', 'MAMMAL', 'VU', 'HERBIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Ngựa vằn đồng bằng', 'Equus quagga', 'MAMMAL', 'NT', 'HERBIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Hồng hạc lớn', 'Phoenicopterus roseus', 'BIRD', 'LC', 'OMNIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Đại bàng vàng', 'Aquila chrysaetos', 'BIRD', 'LC', 'CARNIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Trăn đất Miến Điện', 'Python bivittatus', 'REPTILE', 'VU', 'CARNIVORE');
INSERT INTO species (name, scientific_name, class_group, conservation_status, diet)
VALUES ('Cá mập trắng nhỏ', 'Carcharodon carcharias', 'FISH', 'VU', 'CARNIVORE');

PROMPT === [10] Animals (~22) — có 1 SICK, 1 QUARANTINE ===

-- Hổ
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Raja', 1, 1, 'M', DATE '2015-03-12', DATE '2018-06-01', 'Vườn thú Hà Nội', 190, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Sita', 1, 1, 'F', DATE '2016-08-20', DATE '2019-01-15', 'Sinh tại sở', 160, 'HEALTHY');
-- Voi
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Bông', 2, 2, 'F', DATE '2008-05-01', DATE '2012-09-10', 'Đắk Lắk', 3200, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Thông', 2, 2, 'M', DATE '2010-11-22', DATE '2014-03-01', 'Lâm Đồng', 3500, 'HEALTHY');
-- Gấu trúc
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Bao Bao', 3, 3, 'M', DATE '2014-07-07', DATE '2017-10-01', 'Trung Quốc', 95, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Mei Mei', 3, 3, 'F', DATE '2015-02-14', DATE '2017-10-01', 'Trung Quốc', 88, 'SICK');
-- Sư tử
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Simba', 4, 4, 'M', DATE '2013-01-09', DATE '2016-05-20', 'Kenya', 200, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Nala', 4, 4, 'F', DATE '2014-04-18', DATE '2016-05-20', 'Kenya', 150, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Mufasa', 4, 4, 'M', DATE '2012-09-30', DATE '2015-08-12', 'Nam Phi', 210, 'QUARANTINE');
-- Hươu cao cổ
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Dài', 5, 5, 'M', DATE '2011-06-15', DATE '2015-02-01', 'Tanzania', 1100, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Cao', 5, 5, 'F', DATE '2012-12-01', DATE '2015-02-01', 'Tanzania', 900, 'HEALTHY');
-- Ngựa vằn
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Sọc', 6, 6, 'M', DATE '2017-03-03', DATE '2019-07-20', 'Nam Phi', 280, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Vằn', 6, 6, 'F', DATE '2018-05-25', DATE '2020-01-10', 'Nam Phi', 260, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Stripe', 6, 6, 'M', DATE '2019-08-08', DATE '2021-04-04', 'Sinh tại sở', 240, 'HEALTHY');
-- Hồng hạc
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Hồng 1', 7, 7, 'F', DATE '2018-01-01', DATE '2019-03-15', 'Thái Lan', 3.2, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Hồng 2', 7, 7, 'M', DATE '2018-02-01', DATE '2019-03-15', 'Thái Lan', 3.5, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Hồng 3', 7, 7, 'F', DATE '2019-04-10', DATE '2020-06-01', 'Sinh tại sở', 2.8, 'HEALTHY');
-- Đại bàng
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Ưng', 8, 8, 'M', DATE '2016-09-09', DATE '2018-11-11', 'Lào Cai', 5.5, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Ó', 8, 8, 'F', DATE '2017-01-20', DATE '2019-02-02', 'Hà Giang', 4.8, 'HEALTHY');
-- Trăn
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Nagas', 9, 9, 'M', DATE '2015-05-05', DATE '2018-08-08', 'Campuchia', 45, 'HEALTHY');
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Kaa', 9, 9, 'F', DATE '2016-07-17', DATE '2019-09-09', 'Campuchia', 38, 'HEALTHY');
-- Cá mập
INSERT INTO animals (name, species_id, enclosure_id, gender, birth_date, arrival_date, origin, weight_kg, status)
VALUES ('Sharky', 10, 10, 'F', DATE '2014-10-10', DATE '2017-12-12', 'Nha Trang', 280, 'HEALTHY');

PROMPT === [10] XONG ===
