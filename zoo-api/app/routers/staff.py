from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.deps import Conn, CurrentUser, User, require_roles
from app.repositories import proc_repo

router = APIRouter(prefix="/api/staff", tags=["staff"])


class AssignIn(BaseModel):
    employee_id: int
    enclosure_id: int
    start_date: date
    end_date: date | None = None
    shift: str = Field(pattern="^(MORNING|AFTERNOON|NIGHT)$")


@router.get("/employees")
def employee_details(conn: Conn, user: CurrentUser = Depends(require_roles("MANAGER", "VET", "KEEPER"))):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM v_employee_details ORDER BY employee_id")
        cols = [d[0].lower() for d in cur.description]
        return [dict(zip(cols, r)) for r in cur.fetchall()]


@router.get("/assignments/current")
def current_assignments(conn: Conn, user: CurrentUser = Depends(require_roles("MANAGER", "KEEPER"))):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM v_current_assignments ORDER BY assignment_id")
        cols = [d[0].lower() for d in cur.description]
        return [dict(zip(cols, r)) for r in cur.fetchall()]


@router.post("/assign")
def assign(
    body: AssignIn,
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER")),
):
    proc_repo.call_sp_assign_employee(
        conn, body.employee_id, body.enclosure_id, body.start_date, body.end_date, body.shift
    )
    return {"ok": True}


@router.post("/{employee_id}/resign")
def resign(
    employee_id: int,
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER")),
):
    proc_repo.call_sp_resign_employee(conn, employee_id)
    return {"ok": True, "employee_id": employee_id}
