from __future__ import annotations

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from app.deps import Conn, User
from app.repositories import auth_repo
from app.security import create_access_token, verify_password

router = APIRouter(prefix="/api/auth", tags=["auth"])


class LoginIn(BaseModel):
    username: str = Field(min_length=1)
    password: str = Field(min_length=1)


class LoginOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    username: str
    employee_id: int | None = None
    full_name: str | None = None


@router.post("/login", response_model=LoginOut)
def login(body: LoginIn, conn: Conn):
    acc = auth_repo.fetch_account_by_username(conn, body.username)
    if not acc or not verify_password(body.password, acc["password_hash"]):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Sai tên đăng nhập hoặc mật khẩu.")
    token = create_access_token(
        {"sub": acc["username"], "role": acc["role"], "uid": acc["id"]}
    )
    return LoginOut(
        access_token=token,
        role=acc["role"],
        username=acc["username"],
        employee_id=acc["employee_id"],
        full_name=acc["full_name"],
    )


@router.get("/me")
def me(user: User):
    return {
        "username": user.username,
        "role": user.role,
        "employee_id": user.employee_id,
        "full_name": user.full_name,
    }
