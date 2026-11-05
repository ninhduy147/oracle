"""CRUD tổng quát với whitelist tên bảng/cột — chỉ bind variable cho giá trị."""
from __future__ import annotations

from typing import Any

import oracledb

# Bảng được phép CRUD qua API generic (không gồm bảng trung gian phức tạp)
CRUD_TABLES: dict[str, dict[str, Any]] = {
    "zones": {
        "pk": "id",
        "columns": ["name", "description", "area_m2"],
        "search": ["name"],
    },
    "enclosures": {
        "pk": "id",
        "columns": ["name", "zone_id", "capacity", "status"],
        "search": ["name", "status"],
    },
    "species": {
        "pk": "id",
        "columns": ["name", "scientific_name", "class_group", "conservation_status", "diet"],
        "search": ["name", "class_group"],
    },
    "animals": {
        "pk": "id",
        "columns": [
            "name", "species_id", "enclosure_id", "gender", "birth_date",
            "arrival_date", "origin", "weight_kg", "status",
        ],
        "search": ["name", "status"],
    },
    "positions": {
        "pk": "id",
        "columns": ["name", "base_salary"],
        "search": ["name"],
    },
    "employees": {
        "pk": "id",
        "columns": [
            "full_name", "gender", "birth_date", "phone", "email", "address",
            "hire_date", "position_id", "zone_id", "status",
        ],
        "search": ["full_name", "status"],
    },
    "foods": {
        "pk": "id",
        "columns": ["name", "category", "unit", "stock_qty", "min_stock"],
        "search": ["name", "category"],
    },
    "suppliers": {
        "pk": "id",
        "columns": ["name", "phone", "address"],
        "search": ["name"],
    },
    "ticket_types": {
        "pk": "id",
        "columns": ["name", "price"],
        "search": ["name"],
    },
    "customers": {
        "pk": "id",
        "columns": ["full_name", "phone", "email"],
        "search": ["full_name", "phone"],
    },
    "medical_records": {
        "pk": "id",
        "columns": [
            "animal_id", "vet_id", "exam_date", "diagnosis", "treatment", "follow_up_date",
        ],
        "search": ["diagnosis"],
    },
}


def _ident(name: str) -> str:
    if not name.replace("_", "").isalnum():
        raise ValueError(f"Tên không hợp lệ: {name}")
    return name


def list_rows(
    conn: oracledb.Connection,
    table: str,
    *,
    q: str | None = None,
    page: int = 1,
    page_size: int = 20,
    order_by: str | None = None,
) -> dict[str, Any]:
    meta = CRUD_TABLES[table]
    table = _ident(table)
    page = max(1, page)
    page_size = min(100, max(1, page_size))
    offset = (page - 1) * page_size

    where = ""
    binds: dict[str, Any] = {"lim": page_size, "off": offset}
    if q and meta.get("search"):
        parts = []
        for i, col in enumerate(meta["search"]):
            key = f"q{i}"
            parts.append(f"UPPER({_ident(col)}) LIKE UPPER(:{key})")
            binds[key] = f"%{q}%"
        where = " WHERE " + " OR ".join(parts)

    ob = _ident(order_by) if order_by and order_by.replace("_", "").isalnum() else meta["pk"]

    with conn.cursor() as cur:
        cur.execute(f"SELECT COUNT(*) FROM {table}{where}", {k: v for k, v in binds.items() if k.startswith("q")})
        total = int(cur.fetchone()[0])
        cur.execute(
            f"""
            SELECT * FROM {table}{where}
             ORDER BY {ob}
             OFFSET :off ROWS FETCH NEXT :lim ROWS ONLY
            """,
            binds,
        )
        cols = [d[0].lower() for d in cur.description]
        items = [dict(zip(cols, row)) for row in cur.fetchall()]
    return {"total": total, "page": page, "page_size": page_size, "items": items}


def get_row(conn: oracledb.Connection, table: str, pk_val: int) -> dict[str, Any] | None:
    meta = CRUD_TABLES[table]
    table = _ident(table)
    pk = _ident(meta["pk"])
    with conn.cursor() as cur:
        cur.execute(f"SELECT * FROM {table} WHERE {pk} = :id", {"id": pk_val})
        row = cur.fetchone()
        if not row:
            return None
        cols = [d[0].lower() for d in cur.description]
        return dict(zip(cols, row))


def insert_returning(conn: oracledb.Connection, table: str, data: dict[str, Any]) -> int:
    meta = CRUD_TABLES[table]
    table = _ident(table)
    cols = [c for c in meta["columns"] if c in data]
    if not cols:
        raise ValueError("Không có cột hợp lệ để thêm.")
    col_sql = ", ".join(_ident(c) for c in cols)
    bind_sql = ", ".join(f":{c}" for c in cols)
    binds = {c: data[c] for c in cols}
    pk = _ident(meta["pk"])
    with conn.cursor() as cur:
        out = cur.var(oracledb.DB_TYPE_NUMBER)
        cur.execute(
            f"INSERT INTO {table} ({col_sql}) VALUES ({bind_sql}) RETURNING {pk} INTO :out_id",
            {**binds, "out_id": out},
        )
        return int(out.getvalue()[0])


def update_row(conn: oracledb.Connection, table: str, pk_val: int, data: dict[str, Any]) -> bool:
    meta = CRUD_TABLES[table]
    table = _ident(table)
    cols = [c for c in meta["columns"] if c in data]
    if not cols:
        return False
    sets = ", ".join(f"{_ident(c)} = :{c}" for c in cols)
    binds = {c: data[c] for c in cols}
    binds["id"] = pk_val
    pk = _ident(meta["pk"])
    with conn.cursor() as cur:
        cur.execute(f"UPDATE {table} SET {sets} WHERE {pk} = :id", binds)
        return cur.rowcount > 0


def delete_row(conn: oracledb.Connection, table: str, pk_val: int) -> bool:
    meta = CRUD_TABLES[table]
    table = _ident(table)
    pk = _ident(meta["pk"])
    with conn.cursor() as cur:
        cur.execute(f"DELETE FROM {table} WHERE {pk} = :id", {"id": pk_val})
        return cur.rowcount > 0
