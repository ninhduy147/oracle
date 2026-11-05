from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.deps import Conn, CurrentUser, User, require_roles
from app.repositories import proc_repo

router = APIRouter(prefix="/api/animals", tags=["animals"])


class MoveIn(BaseModel):
    enclosure_id: int = Field(gt=0)


@router.get("/details")
def animal_details(conn: Conn, user: User):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM v_animal_details ORDER BY animal_id")
        cols = [d[0].lower() for d in cur.description]
        return [dict(zip(cols, r)) for r in cur.fetchall()]


@router.get("/{animal_id}/details")
def one_detail(animal_id: int, conn: Conn, user: User):
    with conn.cursor() as cur:
        cur.execute(
            "SELECT * FROM v_animal_details WHERE animal_id = :id",
            {"id": animal_id},
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(404, detail="Không tìm thấy động vật.")
        cols = [d[0].lower() for d in cur.description]
        return dict(zip(cols, row))


@router.post("/{animal_id}/move")
def move_animal(
    animal_id: int,
    body: MoveIn,
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER", "KEEPER", "VET")),
):
    proc_repo.call_sp_move_animal(conn, animal_id, body.enclosure_id)
    free = proc_repo.call_fn_enclosure_free_slots(conn, body.enclosure_id)
    return {"ok": True, "animal_id": animal_id, "enclosure_id": body.enclosure_id, "free_slots": free}


@router.get("/meta/occupancy")
def occupancy(conn: Conn, user: User):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM v_enclosure_occupancy ORDER BY enclosure_id")
        cols = [d[0].lower() for d in cur.description]
        return [dict(zip(cols, r)) for r in cur.fetchall()]
