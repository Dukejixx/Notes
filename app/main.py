"""Punto de entrada de la aplicación FastAPI."""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import cast

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import DBAPIError, OperationalError, SQLAlchemyError

from app.core.config import get_settings
from app.core.database import check_database_connection
from app.routers import notes

logger = logging.getLogger("app")

DB_UNAVAILABLE_MESSAGE = "La base de datos no está disponible. Inténtalo de nuevo más tarde."
DB_ERROR_MESSAGE = "Error interno al acceder a los datos."


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    """Comprueba la conexión al arrancar sin impedir que la API se inicie."""
    try:
        check_database_connection()
    except SQLAlchemyError as exc:
        logger.error(
            "No se pudo conectar a MySQL (%s). Revisa DB_HOST, DB_PORT, DB_USER, "
            "DB_PASSWORD y DB_NAME en .env y que el servidor esté en marcha.",
            _describe_db_error(exc),
        )
    yield


def _describe_db_error(exc: SQLAlchemyError) -> str:
    """Resumen del error del driver. No incluye la URL ni la contraseña."""
    original = getattr(exc, "orig", None)
    return repr(original) if original is not None else type(exc).__name__


def _is_connection_error(exc: SQLAlchemyError) -> bool:
    return isinstance(exc, OperationalError) or (
        isinstance(exc, DBAPIError) and exc.connection_invalidated
    )


async def database_exception_handler(_: Request, exc: Exception) -> JSONResponse:
    """Traduce errores de SQLAlchemy a respuestas sin detalles internos."""
    db_error = cast(SQLAlchemyError, exc)  # Registrado solo para SQLAlchemyError.
    if _is_connection_error(db_error):
        logger.error("Base de datos no disponible: %s", _describe_db_error(db_error))
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"detail": DB_UNAVAILABLE_MESSAGE},
        )
    logger.error("Error de acceso a datos: %s", _describe_db_error(db_error))
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": DB_ERROR_MESSAGE},
    )


def create_app() -> FastAPI:
    settings = get_settings()
    application = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        description="API REST para consultar notas personales almacenadas en MySQL.",
        lifespan=lifespan,
    )
    # La API solo expone lecturas: no se permiten otros métodos ni credenciales.
    application.add_middleware(
        CORSMiddleware,
        allow_origin_regex=settings.cors_origin_regex,
        allow_methods=["GET"],
        allow_headers=["Accept", "Content-Type"],
    )
    application.add_exception_handler(SQLAlchemyError, database_exception_handler)
    application.include_router(notes.router, prefix=settings.api_v1_prefix)
    return application


app = create_app()
