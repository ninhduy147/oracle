"""Connection pool python-oracledb (thin mode — không cần Instant Client)."""
from __future__ import annotations

import oracledb

from app.config import get_settings

_pool: oracledb.ConnectionPool | None = None


def init_pool() -> None:
    global _pool
    if _pool is not None:
        return
    s = get_settings()
    _pool = oracledb.create_pool(
        user=s.oracle_user,
        password=s.oracle_password_zoo,
        dsn=s.dsn,
        min=1,
        max=8,
        increment=1,
        getmode=oracledb.POOL_GETMODE_WAIT,
    )


def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.close(force=True)
        _pool = None


def get_pool() -> oracledb.ConnectionPool:
    if _pool is None:
        init_pool()
    assert _pool is not None
    return _pool


def acquire():
    return get_pool().acquire()
