from __future__ import annotations

from datetime import date

import oracledb
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.deps import Conn, CurrentUser, User, require_roles
from app.repositories import proc_repo

router = APIRouter(prefix="/api/food", tags=["food"])


class FeedIn(BaseModel):
    animal_id: int
    food_id: int
    quantity: float = Field(gt=0)
    note: str | None = None
    employee_id: int | None = None


class PoItemIn(BaseModel):
    food_id: int
    quantity: float = Field(gt=0)
    unit_price: float = Field(ge=0)
    expiry_date: date | None = None


class PurchaseOrderIn(BaseModel):
    supplier_id: int
    employee_id: int | None = None
    items: list[PoItemIn] = Field(min_length=1)


@router.get("/low-stock")
def low_stock(conn: Conn, user: User):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM v_low_stock_foods ORDER BY shortage DESC")
        cols = [d[0].lower() for d in cur.description]
        return [dict(zip(cols, r)) for r in cur.fetchall()]


@router.get("/consumption-30d")
def consumption(conn: Conn, user: User):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM v_food_consumption_30d ORDER BY qty_consumed_30d DESC")
        cols = [d[0].lower() for d in cur.description]
        return [dict(zip(cols, r)) for r in cur.fetchall()]


@router.post("/feed")
def feed(
    body: FeedIn,
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER", "KEEPER")),
):
    emp = body.employee_id or user.employee_id
    if not emp:
        raise HTTPException(400, detail="Thiếu employee_id (tài khoản chưa gắn nhân viên).")
    proc_repo.call_sp_feed_animal(conn, body.animal_id, body.food_id, emp, body.quantity, body.note)
    return {"ok": True}


@router.post("/purchase-orders")
def create_po(
    body: PurchaseOrderIn,
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER", "KEEPER")),
):
    emp = body.employee_id or user.employee_id
    if not emp:
        raise HTTPException(400, detail="Thiếu employee_id.")
    with conn.cursor() as cur:
        out = cur.var(oracledb.DB_TYPE_NUMBER)
        cur.execute(
            """
            INSERT INTO purchase_orders (supplier_id, employee_id)
            VALUES (:s, :e)
            RETURNING id INTO :out_id
            """,
            {"s": body.supplier_id, "e": emp, "out_id": out},
        )
        po_id = int(out.getvalue()[0])
        for it in body.items:
            cur.execute(
                """
                INSERT INTO purchase_order_items
                  (purchase_order_id, food_id, quantity, unit_price, expiry_date)
                VALUES (:po, :f, :q, :p, :x)
                """,
                {
                    "po": po_id,
                    "f": it.food_id,
                    "q": it.quantity,
                    "p": it.unit_price,
                    "x": it.expiry_date,
                },
            )
    return {"ok": True, "purchase_order_id": po_id}
