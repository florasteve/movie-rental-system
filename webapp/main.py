import os
from datetime import datetime, timedelta
from urllib.parse import urlencode

from fastapi import FastAPI, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse, PlainTextResponse
from fastapi.staticfiles import StaticFiles
from jinja2 import Environment, FileSystemLoader, select_autoescape
from sqlalchemy import create_engine, text
from sqlalchemy.exc import ProgrammingError, DBAPIError

# -------------------------
# DB connection
# -------------------------
SQLSERVER_HOST = os.getenv("SQLSERVER_HOST", "host.docker.internal")
SQLSERVER_PORT = int(os.getenv("SQLSERVER_PORT", "1433"))
SQLSERVER_DB   = os.getenv("SQLSERVER_DB",   "MovieRentalDB")
SQLSERVER_USER = os.getenv("SQLSERVER_USER", "SA")
SQLSERVER_PASS = os.getenv("SQLSERVER_PASS", "YourStrong!Passw0rd")
ODBC_DRIVER    = "ODBC Driver 18 for SQL Server"

conn_str = (
    f"mssql+pyodbc://{SQLSERVER_USER}:{SQLSERVER_PASS}"
    f"@{SQLSERVER_HOST}:{SQLSERVER_PORT}/{SQLSERVER_DB}"
    f"?driver={ODBC_DRIVER.replace(' ', '+')}&TrustServerCertificate=yes"
)
engine = create_engine(conn_str, pool_pre_ping=True, pool_recycle=300)

# -------------------------
# App + templating
# -------------------------
app = FastAPI(title="Movie Rental System — Web")
templates = Environment(
    loader=FileSystemLoader(os.path.join(os.path.dirname(__file__), "templates")),
    autoescape=select_autoescape(["html", "jinja"])
)
app.mount(
    "/static",
    StaticFiles(directory=os.path.join(os.path.dirname(__file__), "static")),
    name="static",
)

def render(template_name: str, **ctx) -> HTMLResponse:
    template = templates.get_template(template_name)
    return HTMLResponse(template.render(**ctx))

# -------------------------
# Helpers
# -------------------------
def _clamp(n: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, n))

def _pagination_ctx(request: Request, page: int, size: int, has_next: bool) -> dict:
    base = request.url.path

    def url_for_page(p: int) -> str:
        params = dict(request.query_params)
        params["page"] = str(p)
        params["size"] = str(size)
        return f"{base}?{urlencode(params)}"

    return {
        "page": page,
        "size": size,
        "prev_url": url_for_page(page - 1) if page > 1 else None,
        "next_url": url_for_page(page + 1) if has_next else None,
    }

def _safe_db(callable_):
    """Wrap DB calls to show friendly errors in the UI instead of 500s."""
    try:
        return callable_()
    except ProgrammingError as e:
        msg = str(getattr(e, "orig", e))
        # Known business errors from procs or constraints
        if "Rental not found or already returned" in msg:
            raise HTTPException(status_code=400, detail="Rental not found or already returned.")
        if "Cannot open database" in msg:
            raise HTTPException(status_code=503, detail="Database not reachable.")
        # generic
        raise HTTPException(status_code=400, detail=msg)
    except DBAPIError:
        raise HTTPException(status_code=503, detail="Database error. Please try again.")

# -------------------------
# Pages
# -------------------------
@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return render("index.html", request=request)

@app.get("/healthz", response_class=PlainTextResponse)
def healthz():
    # simple DB ping
    with engine.begin() as conn:
        conn.execute(text("SELECT 1"))
    return PlainTextResponse("ok")

@app.get("/overdue", response_class=HTMLResponse)
def overdue(request: Request):
    page = _clamp(int(request.query_params.get("page", "1") or "1"), 1, 10_000)
    size = _clamp(int(request.query_params.get("size", "25") or "25"), 5, 100)
    offset = (page - 1) * size

    def run():
        with engine.begin() as conn:
            rows = conn.execute(
                text("""
                    SELECT *
                    FROM dbo.vwOverdueRentals
                    ORDER BY DueDate ASC
                    OFFSET :off ROWS FETCH NEXT :sz ROWS ONLY
                """),
                {"off": offset, "sz": size},
            ).mappings().all()
        return rows

    rows = _safe_db(run)
    pager = _pagination_ctx(request, page, size, has_next=(len(rows) == size))
    return render("overdue.html", request=request, rows=rows, pager=pager)

@app.get("/low-inventory", response_class=HTMLResponse)
def low_inventory(request: Request):
    page = _clamp(int(request.query_params.get("page", "1") or "1"), 1, 10_000)
    size = _clamp(int(request.query_params.get("size", "25") or "25"), 5, 100)
    offset = (page - 1) * size

    def run():
        with engine.begin() as conn:
            rows = conn.execute(
                text("""
                    SELECT *
                    FROM dbo.vwLowInventory
                    ORDER BY Available ASC, TitleId ASC
                    OFFSET :off ROWS FETCH NEXT :sz ROWS ONLY
                """),
                {"off": offset, "sz": size},
            ).mappings().all()
        return rows

    rows = _safe_db(run)
    pager = _pagination_ctx(request, page, size, has_next=(len(rows) == size))
    return render("low_inventory.html", request=request, rows=rows, pager=pager)

@app.get("/rent", response_class=HTMLResponse)
def rent_get(request: Request):
    def load_lists():
        with engine.begin() as conn:
            customers = [r[0] for r in conn.execute(text("SELECT TOP (50) CustomerId FROM dbo.Customers ORDER BY CustomerId ASC"))]
            inventory = [r[0] for r in conn.execute(text("""
                SELECT TOP (50) i.InventoryId
                FROM dbo.Inventory i
                WHERE NOT EXISTS (
                    SELECT 1 FROM dbo.Rentals r
                    WHERE r.InventoryId = i.InventoryId AND r.ReturnDate IS NULL
                )
                ORDER BY i.InventoryId ASC
            """))]
        return customers, inventory

    customers, inventory = _safe_db(load_lists)
    return render("rent.html", request=request, default_days=3, customers=customers, inventory=inventory, error=None)

@app.post("/rent", response_class=HTMLResponse)
def rent_post(
    request: Request,
    customer_id: int = Form(...),
    inventory_id: int = Form(...),
    days: int = Form(3),
):
    rental_date = datetime.now()
    due_date = rental_date + timedelta(days=max(1, int(days)))

    def run():
        with engine.begin() as conn:
            open_cnt = conn.execute(
                text("SELECT COUNT(*) FROM dbo.Rentals WHERE InventoryId = :inv AND ReturnDate IS NULL"),
                {"inv": inventory_id},
            ).scalar_one()
            if int(open_cnt) > 0:
                raise HTTPException(status_code=400, detail="That inventory item is currently rented out.")

            conn.execute(
                text(
                    """
                    INSERT INTO dbo.Rentals (CustomerId, InventoryId, RentalDate, DueDate, ReturnDate)
                    VALUES (:cust, :inv, :rdate, :ddate, NULL)
                    """
                ),
                {"cust": customer_id, "inv": inventory_id, "rdate": rental_date, "ddate": due_date},
            )

    try:
        _safe_db(run)
        return RedirectResponse(url="/", status_code=303)
    except HTTPException as e:
        # Re-render form with a friendly message and refreshed lists
        return rent_get(request) if e.status_code >= 500 else render(
            "rent.html",
            request=request,
            default_days=days,
            customers=_safe_db(lambda: [r[0] for r in engine.begin().execute(text("SELECT TOP (50) CustomerId FROM dbo.Customers ORDER BY CustomerId ASC"))]),
            inventory=_safe_db(lambda: [r[0] for r in engine.begin().execute(text("""
                SELECT TOP (50) i.InventoryId
                FROM dbo.Inventory i
                WHERE NOT EXISTS (
                    SELECT 1 FROM dbo.Rentals r
                    WHERE r.InventoryId = i.InventoryId AND r.ReturnDate IS NULL
                )
                ORDER BY i.InventoryId ASC
            """))]),
            error=e.detail,
        )

@app.get("/return", response_class=HTMLResponse)
def return_get(request: Request):
    def load_open():
        with engine.begin() as conn:
            return [r[0] for r in conn.execute(text("SELECT TOP (50) RentalId FROM dbo.Rentals WHERE ReturnDate IS NULL ORDER BY RentalId ASC"))]
    rental_ids = _safe_db(load_open)
    return render("return.html", request=request, rental_ids=rental_ids, error=None)

@app.post("/return", response_class=HTMLResponse)
def return_post(request: Request, rental_id: int = Form(...)):
    def run():
        with engine.begin() as conn:
            conn.execute(text("EXEC dbo.ReturnMovie @RentalId=:rid"), {"rid": rental_id})

    try:
        _safe_db(run)
        return RedirectResponse(url="/", status_code=303)
    except HTTPException as e:
        # Re-render with a friendly message and refreshed open rentals
        return render(
            "return.html",
            request=request,
            rental_ids=_safe_db(lambda: [r[0] for r in engine.begin().execute(text("SELECT TOP (50) RentalId FROM dbo.Rentals WHERE ReturnDate IS NULL ORDER BY RentalId ASC"))]),
            error=e.detail,
        )

# -------------------------
# API snippets for pickers (HTMX populates <select>)
# -------------------------
@app.get("/api/customers/search", response_class=HTMLResponse)
def api_customers_search(q: str = "", limit: int = 50):
    q_like = f"%{q.strip()}%" if q else None
    def run():
        with engine.begin() as conn:
            if q_like:
                rows = conn.execute(
                    text("""
                        SELECT TOP (:lim) CustomerId
                        FROM dbo.Customers
                        WHERE CAST(CustomerId AS varchar(50)) LIKE :pattern
                        ORDER BY CustomerId ASC
                    """),
                    {"lim": limit, "pattern": q_like},
                ).all()
            else:
                rows = conn.execute(
                    text("SELECT TOP (:lim) CustomerId FROM dbo.Customers ORDER BY CustomerId ASC"),
                    {"lim": limit},
                ).all()
        return [r[0] for r in rows]
    ids = _safe_db(run)
    html = "".join(f'<option value="{cid}">{cid}</option>' for cid in ids) or '<option disabled>(none)</option>'
    return HTMLResponse(html)

@app.get("/api/inventory/search", response_class=HTMLResponse)
def api_inventory_search(q: str = "", available: int = 1, limit: int = 50):
    q_like = f"%{q.strip()}%" if q else None
    def run():
        with engine.begin() as conn:
            base = """
                SELECT TOP (:lim) i.InventoryId
                FROM dbo.Inventory i
                {avail_filter}
                {where_q}
                ORDER BY i.InventoryId ASC
            """
            avail_filter = """
                WHERE NOT EXISTS (
                    SELECT 1 FROM dbo.Rentals r
                    WHERE r.InventoryId = i.InventoryId AND r.ReturnDate IS NULL
                )
            """ if available else ""
            where_q = (" AND" if avail_filter else " WHERE") + " CAST(i.InventoryId AS varchar(50)) LIKE :pattern" if q_like else ""
            sql = base.format(avail_filter=avail_filter, where_q=where_q)
            params = {"lim": limit}
            if q_like:
                params["pattern"] = q_like
            rows = conn.execute(text(sql), params).all()
        return [r[0] for r in rows]
    ids = _safe_db(run)
    html = "".join(f'<option value="{iid}">{iid}</option>' for iid in ids) or '<option disabled>(none)</option>'
    return HTMLResponse(html)

@app.get("/api/rentals/open", response_class=HTMLResponse)
def api_rentals_open(q: str = "", limit: int = 50):
    q_like = f"%{q.strip()}%" if q else None
    def run():
        with engine.begin() as conn:
            if q_like:
                rows = conn.execute(
                    text("""
                        SELECT TOP (:lim) RentalId
                        FROM dbo.Rentals
                        WHERE ReturnDate IS NULL
                          AND CAST(RentalId AS varchar(50)) LIKE :pattern
                        ORDER BY RentalId ASC
                    """),
                    {"lim": limit, "pattern": q_like},
                ).all()
            else:
                rows = conn.execute(
                    text("""
                        SELECT TOP (:lim) RentalId
                        FROM dbo.Rentals
                        WHERE ReturnDate IS NULL
                        ORDER BY RentalId ASC
                    """),
                    {"lim": limit},
                ).all()
        return [r[0] for r in rows]
    ids = _safe_db(run)
    html = "".join(f'<option value="{rid}">{rid}</option>' for rid in ids) or '<option disabled>(none)</option>'
    return HTMLResponse(html)
