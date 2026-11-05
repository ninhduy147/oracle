"""JWT + bcrypt — tài khoản app_accounts (khác user Oracle ZOO)."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
import jwt

from app.config import get_settings


def hash_password(plain: str) -> str:
    rounds = get_settings().bcrypt_rounds
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt(rounds)).decode("utf-8")


def verify_password(plain: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), password_hash.encode("utf-8"))
    except ValueError:
        return False


def create_access_token(payload: dict[str, Any]) -> str:
    s = get_settings()
    data = payload.copy()
    data["exp"] = datetime.now(timezone.utc) + timedelta(minutes=s.jwt_expire_minutes)
    return jwt.encode(data, s.jwt_secret, algorithm=s.jwt_algorithm)


def decode_access_token(token: str) -> dict[str, Any]:
    s = get_settings()
    return jwt.decode(token, s.jwt_secret, algorithms=[s.jwt_algorithm])
