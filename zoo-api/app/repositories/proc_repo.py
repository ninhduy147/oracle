"""Gọi procedure / function Oracle — không viết lại logic nghiệp vụ bằng Python."""
from __future__ import annotations

import oracledb


def call_sp_move_animal(conn: oracledb.Connection, animal_id: int, enclosure_id: int) -> None:
    with conn.cursor() as cur:
        cur.callproc("sp_move_animal", [animal_id, enclosure_id])


def call_sp_assign_employee(
    conn: oracledb.Connection,
    employee_id: int,
    enclosure_id: int,
    start,
    end,
    shift: str,
) -> None:
    with conn.cursor() as cur:
        cur.callproc("sp_assign_employee", [employee_id, enclosure_id, start, end, shift])


def call_sp_resign_employee(conn: oracledb.Connection, employee_id: int) -> None:
    with conn.cursor() as cur:
        cur.callproc("sp_resign_employee", [employee_id])


def call_sp_feed_animal(
    conn: oracledb.Connection,
    animal_id: int,
    food_id: int,
    employee_id: int,
    quantity: float,
    note: str | None,
) -> None:
    with conn.cursor() as cur:
        cur.callproc("sp_feed_animal", [animal_id, food_id, employee_id, quantity, note])


def call_sp_create_invoice(
    conn: oracledb.Connection,
    customer_id: int | None,
    employee_id: int,
    payment_method: str,
) -> int:
    with conn.cursor() as cur:
        out_id = cur.var(oracledb.DB_TYPE_NUMBER)
        cur.callproc("sp_create_invoice", [customer_id, employee_id, payment_method, out_id])
        return int(out_id.getvalue())


def call_sp_add_invoice_item(
    conn: oracledb.Connection,
    invoice_id: int,
    ticket_type_id: int,
    quantity: int,
) -> None:
    with conn.cursor() as cur:
        cur.callproc("sp_add_invoice_item", [invoice_id, ticket_type_id, quantity])


def call_fn_revenue(conn: oracledb.Connection, date_from, date_to) -> float:
    with conn.cursor() as cur:
        result = cur.callfunc("fn_revenue", oracledb.DB_TYPE_NUMBER, [date_from, date_to])
        return float(result or 0)


def call_fn_enclosure_free_slots(conn: oracledb.Connection, enclosure_id: int) -> int:
    with conn.cursor() as cur:
        result = cur.callfunc("fn_enclosure_free_slots", oracledb.DB_TYPE_NUMBER, [enclosure_id])
        return int(result)
