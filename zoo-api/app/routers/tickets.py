from __future__ import annotations

from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException

from app.deps import Conn, CurrentUser, User, require_roles
from app.repositories import proc_repo

router = APIRouter(prefix="/api/tickets", tags=["tickets"])


class InvoiceItemIn(BaseModel):
    ticket_type_id: int
    quantity: int = Field(gt=0)


class SaleIn(BaseModel):
    customer_id: int | None = None
    payment_method: str = Field(pattern="^(CASH|CARD|TRANSFER)$")
    items: list[InvoiceItemIn] = Field(min_length=1)
    employee_id: int | None = None


@router.get("/types")
def ticket_types(conn: Conn, user: User):
    with conn.cursor() as cur:
        cur.execute("SELECT id, name, price FROM ticket_types ORDER BY id")
        cols = [d[0].lower() for d in cur.description]
        return [dict(zip(cols, r)) for r in cur.fetchall()]


@router.post("/sale")
def sale(
    body: SaleIn,
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER", "CASHIER")),
):
    emp = body.employee_id or user.employee_id
    if not emp:
        raise HTTPException(400, detail="Thiếu employee_id.")
    inv_id = proc_repo.call_sp_create_invoice(conn, body.customer_id, emp, body.payment_method)
    for it in body.items:
        proc_repo.call_sp_add_invoice_item(conn, inv_id, it.ticket_type_id, it.quantity)
    with conn.cursor() as cur:
        cur.execute(
            "SELECT * FROM v_invoice_details WHERE invoice_id = :id ORDER BY ticket_name",
            {"id": inv_id},
        )
        cols = [d[0].lower() for d in cur.description]
        lines = [dict(zip(cols, r)) for r in cur.fetchall()]
        cur.execute("SELECT total_amount FROM invoices WHERE id = :id", {"id": inv_id})
        total = float(cur.fetchone()[0])
    return {"ok": True, "invoice_id": inv_id, "total_amount": total, "lines": lines}
