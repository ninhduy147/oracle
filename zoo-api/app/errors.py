"""Ánh xạ lỗi Oracle → HTTP + thông báo tiếng Việt."""
from __future__ import annotations

import re

import oracledb
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


def _extract_ora(msg: str) -> tuple[str | None, str]:
    m = re.search(r"(ORA-\d+):\s*(.*)", msg, re.DOTALL)
    if not m:
        return None, msg
    code, text = m.group(1), m.group(2).strip()
    # Bỏ stack PL/SQL phía sau dòng đầu
    text = text.split("\n")[0].strip()
    return code, text


def map_oracle_error(exc: oracledb.Error) -> tuple[int, str]:
    """Trả (http_status, message_vi)."""
    msg = str(exc)
    code, text = _extract_ora(msg)

    if code and code.startswith("ORA-20"):
        # RAISE_APPLICATION_ERROR — giữ nguyên tiếng Việt từ CSDL
        return 400, text or msg

    mapping = {
        "ORA-00001": "Dữ liệu bị trùng khóa (unique/primary key).",
        "ORA-02291": "Vi phạm khóa ngoại: bản ghi cha không tồn tại.",
        "ORA-02292": "Vi phạm khóa ngoại: còn bản ghi con tham chiếu.",
        "ORA-02290": "Vi phạm ràng buộc CHECK.",
        "ORA-01400": "Thiếu giá trị bắt buộc (NOT NULL).",
        "ORA-01722": "Giá trị số không hợp lệ.",
        "ORA-01861": "Định dạng ngày không khớp.",
        "ORA-01017": "Sai tên đăng nhập hoặc mật khẩu Oracle.",
        "ORA-12154": "Không kết nối được Oracle (sai DSN/service).",
        "ORA-12514": "Listener không có service (DB chưa mở?).",
        "ORA-01035": "Database đang RESTRICTED SESSION.",
    }
    if code and code in mapping:
        return 400, mapping[code]
    if code:
        return 400, f"{code}: {text}"
    return 500, "Lỗi cơ sở dữ liệu không xác định."


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(oracledb.Error)
    async def oracle_handler(_request: Request, exc: oracledb.Error):
        status, detail = map_oracle_error(exc)
        return JSONResponse(status_code=status, content={"detail": detail})
