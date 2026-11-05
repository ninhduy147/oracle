from __future__ import annotations

from fastapi import APIRouter

from app.deps import Conn

router = APIRouter(tags=["health"])


@router.get("/api/health")
def health(conn: Conn):
    with conn.cursor() as cur:
        cur.execute("SELECT 1 FROM dual")
        cur.fetchone()
        cur.execute("SELECT USER, SYS_CONTEXT('USERENV','SERVICE_NAME') FROM dual")
        user, service = cur.fetchone()
        cur.execute("SELECT COUNT(*) FROM animals")
        animals = int(cur.fetchone()[0])
    return {
        "status": "ok",
        "oracle_user": user,
        "service": service,
        "animals": animals,
    }
