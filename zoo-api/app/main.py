"""Ứng dụng FastAPI — Swagger tại /docs."""
from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import db
from app.config import get_settings
from app.errors import register_exception_handlers
from app.routers import animals, audit, auth, crud, food, health, reports, staff, tickets


@asynccontextmanager
async def lifespan(_app: FastAPI):
    db.init_pool()
    try:
        yield
    finally:
        db.close_pool()


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="Zoo Management API",
        description="API quản lý sở thú — kết nối Oracle FREEPDB1 (user ZOO).",
        version="1.0.0",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    register_exception_handlers(app)

    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(crud.router)
    app.include_router(animals.router)
    app.include_router(staff.router)
    app.include_router(food.router)
    app.include_router(tickets.router)
    app.include_router(reports.router)
    app.include_router(audit.router)
    return app


app = create_app()
