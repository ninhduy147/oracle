# ERD — Hệ thống quản lý sở thú

Sinh từ schema user `ZOO` (19 bảng) trên PDB `FREEPDB1`.

## Cách xuất ảnh

1. Mở file này trên GitHub / VS Code (Markdown Preview Mermaid) / [mermaid.live](https://mermaid.live)
2. Copy khối `erDiagram` → Export PNG/SVG

## Mermaid ERD

```mermaid
erDiagram
  ZONES ||--o{ ENCLOSURES : has
  ZONES ||--o{ EMPLOYEES : assigns
  ENCLOSURES ||--o{ ANIMALS : houses
  SPECIES ||--o{ ANIMALS : classifies
  POSITIONS ||--o{ EMPLOYEES : holds
  EMPLOYEES ||--o{ ASSIGNMENTS : works
  ENCLOSURES ||--o{ ASSIGNMENTS : covered_by
  EMPLOYEES ||--o| APP_ACCOUNTS : logs_in
  SUPPLIERS ||--o{ PURCHASE_ORDERS : supplies
  EMPLOYEES ||--o{ PURCHASE_ORDERS : creates
  PURCHASE_ORDERS ||--o{ PURCHASE_ORDER_ITEMS : contains
  FOODS ||--o{ PURCHASE_ORDER_ITEMS : ordered
  ANIMALS ||--o{ FEEDING_LOGS : eats
  FOODS ||--o{ FEEDING_LOGS : used_in
  EMPLOYEES ||--o{ FEEDING_LOGS : feeds
  ANIMALS ||--o{ MEDICAL_RECORDS : examined
  EMPLOYEES ||--o{ MEDICAL_RECORDS : vet
  CUSTOMERS ||--o{ INVOICES : buys
  EMPLOYEES ||--o{ INVOICES : sells
  INVOICES ||--o{ INVOICE_ITEMS : lines
  TICKET_TYPES ||--o{ INVOICE_ITEMS : priced

  ZONES {
    number id PK
    varchar name UK
    number area_m2
  }
  ENCLOSURES {
    number id PK
    varchar name
    number zone_id FK
    number capacity
    varchar status
  }
  SPECIES {
    number id PK
    varchar name
    varchar class_group
    varchar diet
  }
  ANIMALS {
    number id PK
    varchar name
    number species_id FK
    number enclosure_id FK
    varchar status
  }
  POSITIONS {
    number id PK
    varchar name UK
    number base_salary
  }
  EMPLOYEES {
    number id PK
    varchar full_name
    number position_id FK
    number zone_id FK
    varchar status
  }
  ASSIGNMENTS {
    number id PK
    number employee_id FK
    number enclosure_id FK
    varchar shift
  }
  APP_ACCOUNTS {
    number id PK
    varchar username UK
    varchar role
    number employee_id FK UK
  }
  FOODS {
    number id PK
    varchar name UK
    varchar category
    number stock_qty
  }
  SUPPLIERS {
    number id PK
    varchar name
  }
  PURCHASE_ORDERS {
    number id PK
    number supplier_id FK
    number employee_id FK
    number total_amount
  }
  PURCHASE_ORDER_ITEMS {
    number purchase_order_id PK_FK
    number food_id PK_FK
    number quantity
    number unit_price
  }
  FEEDING_LOGS {
    number id PK
    number animal_id FK
    number food_id FK
    number employee_id FK
  }
  MEDICAL_RECORDS {
    number id PK
    number animal_id FK
    number vet_id FK
  }
  TICKET_TYPES {
    number id PK
    varchar name UK
    number price
  }
  CUSTOMERS {
    number id PK
    varchar full_name
  }
  INVOICES {
    number id PK
    number customer_id FK
    number employee_id FK
    number total_amount
  }
  INVOICE_ITEMS {
    number invoice_id PK_FK
    number ticket_type_id PK_FK
    number quantity
    number unit_price
  }
  AUDIT_LOGS {
    number id PK
    varchar table_name
    varchar action
  }
```

## Lược đồ quan hệ (text)

```
zones(id PK, name UK, description, area_m2)
enclosures(id PK, name, zone_id FK→zones, capacity, status)
species(id PK, name, scientific_name, class_group, conservation_status, diet)
animals(id PK, name, species_id FK→species, enclosure_id FK→enclosures NULL, gender, birth_date, arrival_date, origin, weight_kg, status)
positions(id PK, name UK, base_salary)
employees(id PK, full_name, ..., position_id FK→positions, zone_id FK→zones NULL, status)
assignments(id PK, employee_id FK→employees, enclosure_id FK→enclosures, start_date, end_date, shift)
app_accounts(id PK, username UK, password_hash, role, employee_id FK→employees UK)
suppliers(id PK, name, phone, address)
foods(id PK, name UK, category, unit, stock_qty, min_stock)
purchase_orders(id PK, supplier_id FK, employee_id FK, order_date, total_amount)
purchase_order_items(purchase_order_id FK ON DELETE CASCADE, food_id FK, quantity, unit_price, expiry_date) PK(po, food)
feeding_logs(id PK, animal_id FK, food_id FK, employee_id FK, fed_at, quantity, note)
medical_records(id PK, animal_id FK, vet_id FK→employees, exam_date, diagnosis, treatment, follow_up_date)
ticket_types(id PK, name UK, price)
customers(id PK, full_name, phone, email)
invoices(id PK, customer_id FK NULL, employee_id FK, issued_at, payment_method, total_amount)
invoice_items(invoice_id FK ON DELETE CASCADE, ticket_type_id FK, quantity, unit_price) PK(invoice, ticket)
audit_logs(id PK, table_name, action, record_id, db_user, created_at, details)
```
