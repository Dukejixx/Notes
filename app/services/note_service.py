"""Lógica de negocio y consultas de las notas.

Todas las fechas se interpretan en UTC: un día `YYYY-MM-DD` abarca desde las
00:00:00 (incluido) hasta las 00:00:00 del día siguiente (excluido).
"""

from datetime import date, datetime, time, timedelta

from sqlalchemy import ColumnElement, func, select
from sqlalchemy.orm import Session

from app.models.note import Note
from app.schemas.note import (
    CategoryStat,
    DailyActivity,
    NoteListResponse,
    NoteRead,
    NoteStatsResponse,
)

# Longitud máxima de un intervalo explícito [from_date, to_date]. Limita el
# tamaño de la serie de actividad rellenada con ceros.
MAX_STATS_RANGE_DAYS = 366


class InvalidDateRangeError(ValueError):
    """El intervalo de fechas solicitado no es válido."""


def list_notes(db: Session, page: int, limit: int) -> NoteListResponse:
    """Devuelve una página de notas ordenadas de la más reciente a la más antigua.

    El `id` desempata notas con el mismo `created_at` para que el orden sea estable
    entre páginas.
    """
    total = db.scalar(select(func.count()).select_from(Note)) or 0
    notes = db.scalars(
        select(Note)
        .order_by(Note.created_at.desc(), Note.id.desc())
        .offset((page - 1) * limit)
        .limit(limit)
    ).all()
    return NoteListResponse(
        items=[NoteRead.model_validate(note) for note in notes],
        total=total,
        page=page,
        limit=limit,
    )


def validate_date_range(from_date: date | None, to_date: date | None) -> None:
    """Rechaza intervalos invertidos o demasiado largos."""
    if from_date is None or to_date is None:
        return
    if from_date > to_date:
        raise InvalidDateRangeError("from_date debe ser anterior o igual a to_date.")
    if (to_date - from_date).days + 1 > MAX_STATS_RANGE_DAYS:
        raise InvalidDateRangeError(f"El intervalo no puede superar {MAX_STATS_RANGE_DAYS} días.")


def get_note_stats(
    db: Session, from_date: date | None = None, to_date: date | None = None
) -> NoteStatsResponse:
    """Calcula las métricas de las notas creadas dentro del alcance indicado.

    Los conteos se agregan en MySQL; en Python solo se calculan porcentajes y se
    rellenan con cero los días sin notas.
    """
    validate_date_range(from_date, to_date)
    filters = _created_at_filters(from_date, to_date)

    category_counts = _count_by_category(db, filters)
    total = sum(count for _, count in category_counts)
    if total == 0:
        return NoteStatsResponse(
            total_notes=0, by_category=[], activity=[], most_used_category=None
        )

    by_category = [
        CategoryStat(category=category, count=count, percentage=round(count * 100 / total, 2))
        for category, count in category_counts
    ]
    daily_counts = _count_by_day(db, filters)
    activity = _fill_missing_days(
        daily_counts,
        start=from_date if from_date and to_date else min(daily_counts),
        end=to_date if from_date and to_date else max(daily_counts),
    )
    return NoteStatsResponse(
        total_notes=total,
        by_category=by_category,
        activity=activity,
        # category_counts está ordenado por conteo descendente y nombre ascendente.
        most_used_category=category_counts[0][0],
    )


def _created_at_filters(from_date: date | None, to_date: date | None) -> list[ColumnElement[bool]]:
    """Condiciones parametrizadas sobre `created_at` (aprovechan sus índices)."""
    filters: list[ColumnElement[bool]] = []
    if from_date is not None:
        filters.append(Note.created_at >= datetime.combine(from_date, time.min))
    if to_date is not None:
        filters.append(Note.created_at < datetime.combine(to_date + timedelta(days=1), time.min))
    return filters


def _count_by_category(db: Session, filters: list[ColumnElement[bool]]) -> list[tuple[str, int]]:
    """Conteo por categoría, de mayor a menor (empates por nombre)."""
    note_count = func.count(Note.id).label("note_count")
    rows = db.execute(
        select(Note.category, note_count)
        .where(*filters)
        .group_by(Note.category)
        .order_by(note_count.desc(), Note.category.asc())
    ).tuples()
    return list(rows.all())


def _count_by_day(db: Session, filters: list[ColumnElement[bool]]) -> dict[date, int]:
    """Conteo de notas por día de creación (UTC)."""
    created_day = func.date(Note.created_at).label("created_day")
    rows = db.execute(
        select(created_day, func.count(Note.id)).where(*filters).group_by(created_day)
    ).tuples()
    return dict(rows.all())


def _fill_missing_days(
    daily_counts: dict[date, int], start: date, end: date
) -> list[DailyActivity]:
    """Serie continua de `start` a `end` con conteo 0 en los días sin notas."""
    days = (end - start).days + 1
    return [
        DailyActivity(date=day, count=daily_counts.get(day, 0))
        for day in (start + timedelta(days=offset) for offset in range(days))
    ]
