-- =============================================================================
-- queries.sql  (user ZOO @ FREEPDB1) — Barem 3: ≥ 10 truy vấn (mục tiêu 15)
-- Mỗi truy vấn: mục đích nghiệp vụ, loại, kết quả mẫu mong đợi, giải thích vấn đáp
-- Lưu ý 26ai: KHÔNG viết comment -- sau dấu ; trên cùng dòng (ORA-03405)
-- =============================================================================

SET DEFINE OFF
SET VERIFY OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK ON

PROMPT ################################################################
PROMPT # Q01 — Cơ bản: lọc + sắp xếp — động vật đang SICK
PROMPT # Loại: SELECT + WHERE + ORDER BY
PROMPT # Mong đợi: ≥1 dòng (Mei Mei), status=SICK, sắp theo name
PROMPT # Vấn đáp: WHERE lọc theo CHECK status; ORDER BY không đổi dữ liệu
PROMPT ################################################################
SELECT a.id, a.name, a.status, a.weight_kg, s.name AS species_name
  FROM animals a
  JOIN species s ON s.id = a.species_id
 WHERE a.status = 'SICK'
 ORDER BY a.name;

PROMPT ################################################################
PROMPT # Q02 — Cơ bản: LIKE / BETWEEN / IN
PROMPT # Mục đích: động vật thuộc nhóm MAMMAL, cân nặng 50–500 kg, tên có chữ a
PROMPT # Mong đợi: vài dòng (vd Bao Bao, Nala, Raja...)
PROMPT # Vấn đáp: LIKE phân biệt hoa thường theo NLS; BETWEEN gồm biên
PROMPT ################################################################
SELECT a.id, a.name, a.weight_kg, s.class_group, a.status
  FROM animals a
  JOIN species s ON s.id = a.species_id
 WHERE s.class_group = 'MAMMAL'
   AND a.weight_kg BETWEEN 50 AND 500
   AND UPPER(a.name) LIKE '%A%'
   AND a.status IN ('HEALTHY','SICK','QUARANTINE')
 ORDER BY a.weight_kg DESC;

PROMPT ################################################################
PROMPT # Q03 — Cơ bản: DISTINCT + FETCH FIRST
PROMPT # Mục đích: 5 nguồn gốc (origin) khác nhau gần đây nhất theo arrival
PROMPT # Mong đợi: tối đa 5 dòng origin DISTINCT
PROMPT # Vấn đáp: FETCH FIRST = top-N; DISTINCT loại trùng
PROMPT ################################################################
SELECT DISTINCT a.origin
  FROM animals a
 WHERE a.origin IS NOT NULL
 ORDER BY a.origin
 FETCH FIRST 5 ROWS ONLY;

PROMPT ################################################################
PROMPT # Q04 — Nối bảng: INNER JOIN nhiều bảng (động vật-loài-chuồng-khu)
PROMPT # Mục đích: hồ sơ đầy đủ động vật đang ở chuồng ACTIVE
PROMPT # Mong đợi: ~20 dòng (trừ động vật không có enclosure nếu có)
PROMPT # Vấn đáp: INNER JOIN loại bản ghi không khớp mọi phía
PROMPT ################################################################
SELECT a.id AS animal_id,
       a.name AS animal_name,
       s.name AS species_name,
       s.class_group,
       e.name AS enclosure_name,
       z.name AS zone_name,
       a.status
  FROM animals a
  JOIN species s    ON s.id = a.species_id
  JOIN enclosures e ON e.id = a.enclosure_id
  JOIN zones z      ON z.id = e.zone_id
 WHERE e.status = 'ACTIVE'
 ORDER BY z.name, e.name, a.name;

PROMPT ################################################################
PROMPT # Q05 — Nối bảng: LEFT JOIN — chuồng chưa có động vật (hoặc trống thực tế)
PROMPT # Mục đích: tìm chuồng không có động vật còn sống/đang nuôi
PROMPT # Mong đợi: ít nhất chuồng bảo trì (id=11) và có thể chuồng trống khác
PROMPT # Vấn đáp: LEFT JOIN + IS NULL = anti-join
PROMPT ################################################################
SELECT e.id, e.name, e.status, e.capacity, z.name AS zone_name
  FROM enclosures e
  JOIN zones z ON z.id = e.zone_id
  LEFT JOIN animals a
    ON a.enclosure_id = e.id
   AND a.status NOT IN ('DECEASED','TRANSFERRED')
 WHERE a.id IS NULL
 ORDER BY e.id;

PROMPT ################################################################
PROMPT # Q06 — Nối 4 bảng: lịch cho ăn kèm nhân viên / thức ăn / động vật / loài
PROMPT # Mục đích: nhật ký cho ăn 7 ngày gần đây để kiểm soát chăm sóc
PROMPT # Mong đợi: nhiều dòng feeding_logs gần đây
PROMPT # Vấn đáp: JOIN nhiều bảng theo FK; lọc theo TIMESTAMP
PROMPT ################################################################
SELECT fl.id,
       fl.fed_at,
       a.name AS animal_name,
       s.name AS species_name,
       f.name AS food_name,
       fl.quantity,
       f.unit,
       e.full_name AS keeper_name
  FROM feeding_logs fl
  JOIN animals a   ON a.id = fl.animal_id
  JOIN species s   ON s.id = a.species_id
  JOIN foods f     ON f.id = fl.food_id
  JOIN employees e ON e.id = fl.employee_id
 WHERE fl.fed_at >= SYSTIMESTAMP - INTERVAL '7' DAY
 ORDER BY fl.fed_at DESC;

PROMPT ################################################################
PROMPT # Q07 — Nhóm: GROUP BY + HAVING — khu vực có > 3 động vật
PROMPT # Mục đích: ưu tiên phân bổ nhân sự cho khu đông
PROMPT # Mong đợi: một số zone (vd châu Á / châu Phi)
PROMPT # Vấn đáp: HAVING lọc sau gom nhóm; WHERE lọc trước
PROMPT ################################################################
SELECT z.id, z.name, COUNT(a.id) AS animal_count
  FROM zones z
  JOIN enclosures e ON e.zone_id = z.id
  JOIN animals a    ON a.enclosure_id = e.id
 WHERE a.status NOT IN ('DECEASED','TRANSFERRED')
 GROUP BY z.id, z.name
HAVING COUNT(a.id) > 3
 ORDER BY animal_count DESC;

PROMPT ################################################################
PROMPT # Q08 — Nhóm: doanh thu theo ngày
PROMPT # Mục đích: theo dõi doanh thu bán vé 14 ngày
PROMPT # Mong đợi: nhiều ngày có revenue > 0
PROMPT # Vấn đáp: TRUNC(date) gom theo ngày; SUM tổng tiền
PROMPT ################################################################
SELECT TRUNC(i.issued_at) AS sale_date,
       COUNT(*) AS invoice_count,
       SUM(i.total_amount) AS revenue
  FROM invoices i
 GROUP BY TRUNC(i.issued_at)
 ORDER BY sale_date DESC;

PROMPT ################################################################
PROMPT # Q09 — Nhóm: số động vật theo class_group
PROMPT # Mục đích: cơ cấu bộ loài trong sở thú
PROMPT # Mong đợi: MAMMAL nhiều nhất, có BIRD/REPTILE/FISH
PROMPT # Vấn đáp: JOIN + GROUP BY cột phân loại
PROMPT ################################################################
SELECT s.class_group, COUNT(a.id) AS animal_count
  FROM species s
  JOIN animals a ON a.species_id = s.id
 WHERE a.status NOT IN ('DECEASED','TRANSFERRED')
 GROUP BY s.class_group
 ORDER BY animal_count DESC;

PROMPT ################################################################
PROMPT # Q10 — Lồng nhau: IN — động vật thuộc loài nguy cấp EN/CR
PROMPT # Mục đích: danh sách ưu tiên bảo tồn
PROMPT # Mong đợi: hổ, voi (EN)...
PROMPT # Vấn đáp: subquery trả tập id; IN kiểm tra thành viên
PROMPT ################################################################
SELECT a.id, a.name, s.name AS species_name, s.conservation_status
  FROM animals a
  JOIN species s ON s.id = a.species_id
 WHERE a.species_id IN (
         SELECT id FROM species
          WHERE conservation_status IN ('EN','CR')
       )
 ORDER BY s.conservation_status, a.name;

PROMPT ################################################################
PROMPT # Q11 — Lồng nhau: NOT EXISTS — nhân viên chưa từng được phân công chuồng
PROMPT # Mục đích: tìm người chưa có assignments (Manager/Cashier/Vet/Security)
PROMPT # Mong đợi: vài employee không phải keeper được gán
PROMPT # Vấn đáp: NOT EXISTS = anti-semi-join, thường tối ưu hơn NOT IN với NULL
PROMPT ################################################################
SELECT e.id, e.full_name, p.name AS position_name
  FROM employees e
  JOIN positions p ON p.id = e.position_id
 WHERE NOT EXISTS (
         SELECT 1 FROM assignments asg
          WHERE asg.employee_id = e.id
       )
 ORDER BY e.id;

PROMPT ################################################################
PROMPT # Q12 — Lồng nhau: subquery tương quan — động vật nặng hơn TB cùng loài
PROMPT # Mục đích: phát hiện cá thể lớn bất thường / chuẩn bị khẩu phần
PROMPT # Mong đợi: vài dòng (con đực nặng hơn cái cùng loài)
PROMPT # Vấn đáp: subquery tương quan chạy theo từng dòng ngoài
PROMPT ################################################################
SELECT a.id, a.name, a.weight_kg, s.name AS species_name,
       (SELECT ROUND(AVG(a2.weight_kg),2)
          FROM animals a2
         WHERE a2.species_id = a.species_id) AS avg_species_weight
  FROM animals a
  JOIN species s ON s.id = a.species_id
 WHERE a.weight_kg > (
         SELECT AVG(a2.weight_kg)
           FROM animals a2
          WHERE a2.species_id = a.species_id
       )
 ORDER BY s.name, a.weight_kg DESC;

PROMPT ################################################################
PROMPT # Q13 — Lồng nhau: subquery ở FROM — top khu theo số động vật
PROMPT # Mục đích: xếp hạng khu để báo cáo quản lý
PROMPT # Mong đợi: 5 khu kèm animal_count
PROMPT # Vấn đáp: inline view / derived table trong FROM
PROMPT ################################################################
SELECT z.name AS zone_name, x.animal_count
  FROM (
        SELECT e.zone_id, COUNT(a.id) AS animal_count
          FROM enclosures e
          LEFT JOIN animals a
            ON a.enclosure_id = e.id
           AND a.status NOT IN ('DECEASED','TRANSFERRED')
         GROUP BY e.zone_id
       ) x
  JOIN zones z ON z.id = x.zone_id
 ORDER BY x.animal_count DESC;

PROMPT ################################################################
PROMPT # Q14 — Hàm thống kê: COUNT/SUM/AVG/MIN/MAX/STDDEV/MEDIAN cân nặng
PROMPT # Mục đích: thống kê cân nặng thú MAMMAL còn nuôi
PROMPT # Mong đợi: 1 dòng tổng hợp
PROMPT # Vấn đáp: hàm nhóm; MEDIAN ít nhạy outlier hơn AVG
PROMPT ################################################################
SELECT COUNT(a.id)              AS cnt,
       ROUND(SUM(a.weight_kg),1) AS sum_kg,
       ROUND(AVG(a.weight_kg),1) AS avg_kg,
       MIN(a.weight_kg)          AS min_kg,
       MAX(a.weight_kg)          AS max_kg,
       ROUND(STDDEV(a.weight_kg),1) AS stddev_kg,
       MEDIAN(a.weight_kg)       AS median_kg
  FROM animals a
  JOIN species s ON s.id = a.species_id
 WHERE s.class_group = 'MAMMAL'
   AND a.status NOT IN ('DECEASED','TRANSFERRED')
   AND a.weight_kg IS NOT NULL;

PROMPT ################################################################
PROMPT # Q15 — Window: RANK thức ăn tiêu thụ 30 ngày
PROMPT # Mục đích: biết món nào tiêu thụ nhiều để đặt hàng
PROMPT # Mong đợi: xếp hạng foods theo tổng quantity
PROMPT # Vấn đáp: RANK() OVER — hạng bằng nhau thì nhảy số
PROMPT ################################################################
SELECT f.name AS food_name,
       f.unit,
       NVL(SUM(fl.quantity),0) AS qty_30d,
       RANK() OVER (ORDER BY NVL(SUM(fl.quantity),0) DESC) AS consumption_rank
  FROM foods f
  LEFT JOIN feeding_logs fl
    ON fl.food_id = f.id
   AND fl.fed_at >= SYSTIMESTAMP - INTERVAL '30' DAY
 GROUP BY f.id, f.name, f.unit
 ORDER BY consumption_rank;

PROMPT ################################################################
PROMPT # Q16 — Window: DENSE_RANK / ROW_NUMBER nhân viên bán vé
PROMPT # Mục đích: xếp hạng thu ngân theo doanh thu
PROMPT # Mong đợi: cashier01/02 có hạng
PROMPT # Vấn đáp: DENSE_RANK không nhảy hạng; ROW_NUMBER luôn duy nhất
PROMPT ################################################################
SELECT e.full_name,
       COUNT(i.id) AS invoice_count,
       SUM(i.total_amount) AS revenue,
       DENSE_RANK() OVER (ORDER BY SUM(i.total_amount) DESC) AS dense_rank_rev,
       ROW_NUMBER() OVER (ORDER BY SUM(i.total_amount) DESC, e.id) AS row_num
  FROM employees e
  JOIN invoices i ON i.employee_id = e.id
 GROUP BY e.id, e.full_name
 ORDER BY revenue DESC;

PROMPT ################################################################
PROMPT # Q17 — ROLLUP + LISTAGG: doanh thu theo phương thức + tổng; tên vé theo HĐ
PROMPT # Mục đích: báo cáo thanh toán và xem nhanh các loại vé trong 1 HĐ
PROMPT # Mong đợi: CASH/CARD/TRANSFER + dòng tổng ROLLUP; LISTAGG tên vé
PROMPT # Vấn đáp: ROLLUP thêm mức tổng; LISTAGG nối chuỗi nhóm
PROMPT # ROLLUP: dong payment_method NULL = tong (tat ca phuong thuc)
PROMPT ################################################################
SELECT payment_method,
       COUNT(*) AS invoice_count,
       SUM(total_amount) AS revenue
  FROM invoices
 GROUP BY ROLLUP(payment_method)
 ORDER BY payment_method NULLS LAST;

PROMPT >>> LISTAGG mau: 5 hoa don gan nhat
SELECT i.id AS invoice_id,
       LISTAGG(tt.name || ' x' || ii.quantity, ', ')
         WITHIN GROUP (ORDER BY tt.name) AS ticket_list,
       i.total_amount
  FROM invoices i
  JOIN invoice_items ii ON ii.invoice_id = i.id
  JOIN ticket_types tt  ON tt.id = ii.ticket_type_id
 GROUP BY i.id, i.total_amount, i.issued_at
 ORDER BY i.issued_at DESC
 FETCH FIRST 5 ROWS ONLY;

PROMPT ################################################################
PROMPT # Q18 — Tập hợp: UNION / INTERSECT / MINUS
PROMPT # Mục đích:
PROMPT #   UNION: id nhân viên từng cho ăn HOẶC từng bán vé
PROMPT #   INTERSECT: vừa cho ăn vừa bán vé (thường rỗng)
PROMPT #   MINUS: đã cho ăn nhưng chưa từng bán vé
PROMPT # Vấn đáp: UNION loại trùng; UNION ALL giữ trùng; MINUS = hiệu tập
PROMPT ################################################################
PROMPT >>> UNION (loai trung cap employee_id + activity)
SELECT employee_id, activity FROM (
  SELECT employee_id, 'FEED' AS activity FROM feeding_logs
  UNION
  SELECT employee_id, 'SALE' AS activity FROM invoices
)
ORDER BY employee_id, activity;

PROMPT >>> INTERSECT (cung employee_id)
SELECT employee_id FROM feeding_logs
INTERSECT
SELECT employee_id FROM invoices
ORDER BY 1;

PROMPT >>> MINUS (cho an ma chua ban ve)
SELECT employee_id FROM feeding_logs
MINUS
SELECT employee_id FROM invoices
ORDER BY 1;

PROMPT ################################################################
PROMPT # queries.sql XONG — 18 truy vấn (Q01–Q18)
PROMPT ################################################################
EXIT;
