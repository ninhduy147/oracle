"""FastAPI dependencies: DB connection, current user, role check."""
from __future__ import annotations

from collections.abc import Generator
from typing import Annotated

import oracledb
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWTError

from app import db
from app.security import decode_access_token

bearer = HTTPBearer(auto_error=False)


def get_conn() -> Generator[oracledb.Connection, None, None]:
    conn = db.acquire()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


Conn = Annotated[oracledb.Connection, Depends(get_conn)]


class CurrentUser:
    def __init__(
        self,
        account_id: int,
        username: str,
        role: str,
        employee_id: int | None,
        full_name: str | None = None,
    ):
        self.account_id = account_id
        self.username = username
        self.role = role
        self.employee_id = employee_id
        self.full_name = full_name


def get_current_user(
    conn: Conn,
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
) -> CurrentUser:
    if creds is None or not creds.credentials:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Chưa đăng nhập.")
    try:
        payload = decode_access_token(creds.credentials)
    except PyJWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Token không hợp lệ hoặc hết hạn.")

    username = payload.get("sub")
    if not username:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Token thiếu subject.")

    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT a.id, a.username, a.role, a.employee_id, e.full_name
              FROM app_accounts a
              LEFT JOIN employees e ON e.id = a.employee_id
             WHERE a.username = :u
            """,
            {"u": username},
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Tài khoản không tồn tại.")
    return CurrentUser(
        account_id=int(row[0]),
        username=row[1],
        role=row[2],
        employee_id=int(row[3]) if row[3] is not None else None,
        full_name=row[4],
    )


User = Annotated[CurrentUser, Depends(get_current_user)]


def require_roles(*roles: str):
    """Dependency: chỉ cho phép các role cho trước. Dùng: user=Depends(require_roles(...))."""

    def _checker(
        user: Annotated[CurrentUser, Depends(get_current_user)],
    ) -> CurrentUser:
        if user.role not in roles:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                detail=f"Không đủ quyền (cần {', '.join(roles)}; hiện tại {user.role}).",
            )
        return user

    return _checker
