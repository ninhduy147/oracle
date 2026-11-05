from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from app.deps import Conn, CurrentUser, User, require_roles

router = APIRouter(prefix="/api/audit", tags=["audit"])


@router.get("/logs")
def audit_logs(
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER")),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
):
    offset = (page - 1) * page_size
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM audit_logs")
        total = int(cur.fetchone()[0])
        cur.execute(
            """
            SELECT id, table_name, action, record_id, db_user, created_at, details
              FROM audit_logs
             ORDER BY created_at DESC
             OFFSET :off ROWS FETCH NEXT :lim ROWS ONLY
            """,
            {"off": offset, "lim": page_size},
        )
        cols = [d[0].lower() for d in cur.description]
        items = []
        for r in cur.fetchall():
            d = dict(zip(cols, r))
            if d.get("created_at") is not None:
                d["created_at"] = str(d["created_at"])
            items.append(d)
    return {"total": total, "page": page, "page_size": page_size, "items": items}
