-- =============================================================================
-- 05_common.sql  (user ZOO)
-- Làm gì: bảng audit_logs dùng chung cho trigger ghi nhật ký
-- Tablespace: ZOO_DATA
-- =============================================================================

PROMPT === [05] audit_logs ===

CREATE TABLE audit_logs (
  id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name  VARCHAR2(64)  NOT NULL,
  action      VARCHAR2(32)  NOT NULL,
  record_id   NUMBER,
  db_user     VARCHAR2(128) DEFAULT USER NOT NULL,
  created_at  TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
  details     VARCHAR2(4000)
) TABLESPACE ZOO_DATA;

CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at) TABLESPACE ZOO_DATA;

COMMENT ON TABLE audit_logs IS 'Nhật ký thay đổi nghiệp vụ (trigger / job)';
COMMENT ON COLUMN audit_logs.db_user IS 'USER Oracle thực hiện thao tác';

PROMPT === [05] XONG ===
