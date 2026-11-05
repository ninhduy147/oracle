# 7.5 Data Pump — Export / Import schema ZOO

## Vì sao Data Pump thay vì `exp`/`imp` cũ?
- Nhanh hơn (song song, dump binary), hỗ trợ `NETWORK_LINK`, `REMAP_*`, `EXCLUDE`/`INCLUDE`, ước lượng.
- `exp`/`imp` cổ điển đã lỗi thời, ít được Oracle khuyến nghị từ 11g+.

## Tham số hay dùng
| Tham số | Ý nghĩa |
|---|---|
| `SCHEMAS` | Export/import theo schema |
| `DIRECTORY` | Object DIRECTORY trỏ thư mục OS |
| `DUMPFILE` | File `.dmp` (`%U` = nhiều file) |
| `TABLE_EXISTS_ACTION` | `SKIP` / `REPLACE` / `TRUNCATE` / `APPEND` khi bảng đích đã có |
| `CONTENT` | `ALL` / `DATA_ONLY` / `METADATA_ONLY` |
| `EXCLUDE` / `INCLUDE` | Lọc object (`EXCLUDE=STATISTICS`) |
| `REMAP_SCHEMA` | Đổi schema khi import (`ZOO:ZOO_COPY`) |
| `REMAP_TABLESPACE` | Đổi tablespace |

## Cách chạy
```bash
# macOS
./scripts/mac/dp-export.sh
./scripts/mac/dp-import.sh

# hoặc
docker compose exec db bash /admin/05_datapump_export.sh
docker compose exec db bash /admin/05_datapump_import.sh
```

## Kết quả thực tế
Xem `docs/ADMIN_RUNBOOK.md` mục 7.5.
