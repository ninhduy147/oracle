from __future__ import annotations

from datetime import date, timedelta

from fastapi import APIRouter, Depends

from app.deps import Conn, CurrentUser, User, require_roles
from app.repositories import proc_repo

router = APIRouter(prefix="/api/reports", tags=["reports"])


@router.get("/overview")
def overview(conn: Conn, user: User):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
              (SELECT COUNT(*) FROM animals WHERE status NOT IN ('DECEASED','TRANSFERRED')) AS animals,
              (SELECT COUNT(*) FROM employees WHERE status='ACTIVE') AS employees,
              (SELECT COUNT(*) FROM v_low_stock_foods) AS low_stock,
              (SELECT COUNT(*) FROM v_upcoming_followups) AS followups
            FROM dual
            """
        )
        a, e, low, fu = cur.fetchone()

        cur.execute(
            """
            SELECT sale_date, revenue FROM v_daily_revenue
             WHERE sale_date >= TRUNC(SYSDATE) - 6
             ORDER BY sale_date
            """
        )
        revenue_7d = [
            {"sale_date": str(r[0].date() if hasattr(r[0], "date") else r[0]), "revenue": float(r[1] or 0)}
            for r in cur.fetchall()
        ]

        cur.execute(
            """
            SELECT s.class_group, COUNT(a.id) AS cnt
              FROM species s
              JOIN animals a ON a.species_id = s.id
             WHERE a.status NOT IN ('DECEASED','TRANSFERRED')
             GROUP BY s.class_group
             ORDER BY cnt DESC
            """
        )
        by_class = [{"class_group": r[0], "count": int(r[1])} for r in cur.fetchall()]

        cur.execute("SELECT * FROM v_low_stock_foods ORDER BY shortage DESC")
        cols = [d[0].lower() for d in cur.description]
        low_rows = [dict(zip(cols, r)) for r in cur.fetchall()]

        cur.execute("SELECT * FROM v_upcoming_followups ORDER BY follow_up_date")
        cols = [d[0].lower() for d in cur.description]
        fu_rows = [dict(zip(cols, r)) for r in cur.fetchall()]

    return {
        "cards": {
            "animals": int(a),
            "employees": int(e),
            "low_stock": int(low),
            "followups": int(fu),
        },
        "revenue_7d": revenue_7d,
        "animals_by_class": by_class,
        "low_stock_foods": low_rows,
        "upcoming_followups": fu_rows,
    }


@router.get("/revenue")
def revenue(
    conn: Conn,
    user: CurrentUser = Depends(require_roles("MANAGER", "CASHIER")),
    date_from: date | None = None,
    date_to: date | None = None,
):
    if date_to is None:
        date_to = date.today()
    if date_from is None:
        date_from = date_to - timedelta(days=13)
    total = proc_repo.call_fn_revenue(conn, date_from, date_to)
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT sale_date, invoice_count, revenue
              FROM v_daily_revenue
             WHERE sale_date BETWEEN :f AND :t
             ORDER BY sale_date
            """,
            {"f": date_from, "t": date_to},
        )
        cols = [d[0].lower() for d in cur.description]
        days = []
        for r in cur.fetchall():
            item = dict(zip(cols, r))
            if hasattr(item["sale_date"], "date"):
                item["sale_date"] = str(item["sale_date"].date())
            else:
                item["sale_date"] = str(item["sale_date"])
            item["revenue"] = float(item["revenue"] or 0)
            item["invoice_count"] = int(item["invoice_count"])
            days.append(item)
    return {"date_from": str(date_from), "date_to": str(date_to), "total": total, "days": days}
