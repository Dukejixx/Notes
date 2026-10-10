"""Endpoints de las notas (versión 1 de la API)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.note import NoteListResponse, NoteStatsResponse
from app.services import note_service

MAX_PAGE_SIZE = 100
DEFAULT_PAGE_SIZE = 10

router = APIRouter(prefix="/notes", tags=["notes"])

DbSession = Annotated[Session, Depends(get_db)]

DB_ERROR_RESPONSES: dict[int | str, dict[str, str]] = {
    status.HTTP_503_SERVICE_UNAVAILABLE: {"description": "La base de datos no está disponible."},
    status.HTTP_500_INTERNAL_SERVER_ERROR: {"description": "Error interno de acceso a datos."},
}


@router.get(
    "/stats",
    response_model=NoteStatsResponse,
    summary="Estadísticas de notas para gráficas",
    responses=DB_ERROR_RESPONSES,
)
def get_note_stats(
    db: DbSession,
    from_date: Annotated[
        date | None,
        Query(description="Fecha inicial incluida (YYYY-MM-DD, UTC)."),
    ] = None,
    to_date: Annotated[
        date | None,
        Query(description="Fecha final incluida (YYYY-MM-DD, UTC)."),
    ] = None,
) -> NoteStatsResponse:
    """Total, distribución por categoría, actividad diaria y categoría más usada.

    Todas las métricas usan el mismo alcance temporal. Si se indican ambas fechas
    (máximo 366 días), `activity` cubre el intervalo completo; en otro caso cubre
    desde el primer hasta el último día con notas. Los días sin notas aparecen con
    `count: 0`.
    """
    try:
        return note_service.get_note_stats(db, from_date=from_date, to_date=to_date)
    except note_service.InvalidDateRangeError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(exc)
        ) from exc


@router.get(
    "",
    response_model=NoteListResponse,
    summary="Listar notas",
    responses=DB_ERROR_RESPONSES,
)
def list_notes(
    db: DbSession,
    page: Annotated[int, Query(ge=1, description="Número de página, empezando en 1.")] = 1,
    limit: Annotated[
        int, Query(ge=1, le=MAX_PAGE_SIZE, description="Notas por página (máximo 100).")
    ] = DEFAULT_PAGE_SIZE,
) -> NoteListResponse:
    """Notas ordenadas por fecha de creación descendente, con paginación."""
    return note_service.list_notes(db, page=page, limit=limit)
