from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query

from app.deps import Conn, CurrentUser, User, require_roles
from app.repositories import crud as crud_repo

router = APIRouter(prefix="/api/crud", tags=["crud"])

# Ai được ghi (CREATE/UPDATE/DELETE) theo bảng
WRITE_ROLES: dict[str, tuple[str, ...]] = {
    "zones": ("MANAGER",),
    "enclosures": ("MANAGER",),
    "species": ("MANAGER", "VET"),
    "animals": ("MANAGER", "VET", "KEEPER"),
    "positions": ("MANAGER",),
    "employees": ("MANAGER",),
    "foods": ("MANAGER", "KEEPER"),
    "suppliers": ("MANAGER",),
    "ticket_types": ("MANAGER",),
    "customers": ("MANAGER", "CASHIER"),
    "medical_records": ("MANAGER", "VET"),
}


def _table(name: str) -> str:
    if name not in crud_repo.CRUD_TABLES:
        raise HTTPException(404, detail=f"Bảng không được phép: {name}")
    return name


@router.get("/{table}")
def list_table(
    table: str,
    conn: Conn,
    user: User,
    q: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    table = _table(table)
    return crud_repo.list_rows(conn, table, q=q, page=page, page_size=page_size)


@router.get("/{table}/{item_id}")
def get_item(table: str, item_id: int, conn: Conn, user: User):
    table = _table(table)
    row = crud_repo.get_row(conn, table, item_id)
    if not row:
        raise HTTPException(404, detail="Không tìm thấy bản ghi.")
    return row


@router.post("/{table}", status_code=201)
def create_item(table: str, body: dict[str, Any], conn: Conn, user: User):
    table = _table(table)
    roles = WRITE_ROLES.get(table, ("MANAGER",))
    if user.role not in roles:
        raise HTTPException(403, detail="Không đủ quyền ghi.")
    new_id = crud_repo.insert_returning(conn, table, body)
    return crud_repo.get_row(conn, table, new_id)


@router.put("/{table}/{item_id}")
def update_item(table: str, item_id: int, body: dict[str, Any], conn: Conn, user: User):
    table = _table(table)
    roles = WRITE_ROLES.get(table, ("MANAGER",))
    if user.role not in roles:
        raise HTTPException(403, detail="Không đủ quyền ghi.")
    ok = crud_repo.update_row(conn, table, item_id, body)
    if not ok:
        raise HTTPException(404, detail="Không tìm thấy hoặc không có trường cập nhật.")
    return crud_repo.get_row(conn, table, item_id)


@router.delete("/{table}/{item_id}")
def delete_item(
    table: str,
    item_id: int,
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER")),
):
    table = _table(table)
    if not crud_repo.delete_row(conn, table, item_id):
        raise HTTPException(404, detail="Không tìm thấy bản ghi.")
    return {"ok": True, "id": item_id}
