from __future__ import annotations

import oracledb


def fetch_account_by_username(conn: oracledb.Connection, username: str) -> dict | None:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT a.id, a.username, a.password_hash, a.role, a.employee_id, e.full_name
              FROM app_accounts a
              LEFT JOIN employees e ON e.id = a.employee_id
             WHERE a.username = :u
            """,
            {"u": username},
        )
        row = cur.fetchone()
        if not row:
            return None
        return {
            "id": int(row[0]),
            "username": row[1],
            "password_hash": row[2],
            "role": row[3],
            "employee_id": int(row[4]) if row[4] is not None else None,
            "full_name": row[5],
        }
