"""Esquemas Pydantic de entrada y salida de las notas."""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field


class NoteRead(BaseModel):
    """Campos públicos de una nota."""

    model_config = ConfigDict(from_attributes=True)

    id: int = Field(examples=[1])
    title: str = Field(examples=["Aprender FastAPI"])
    content: str = Field(examples=["Estudiar endpoints y dependencias"])
    category: str = Field(examples=["Estudio"])
    created_at: datetime = Field(description="Fecha de creación (UTC).")
    updated_at: datetime = Field(description="Fecha de la última actualización (UTC).")


class NoteListResponse(BaseModel):
    """Página de notas ordenadas por fecha de creación descendente."""

    items: list[NoteRead]
    total: int = Field(ge=0, description="Número total de notas almacenadas.")
    page: int = Field(ge=1)
    limit: int = Field(ge=1)


class CategoryStat(BaseModel):
    """Número de notas de una categoría y su porcentaje sobre el total del alcance."""

    category: str = Field(examples=["Estudio"])
    count: int = Field(ge=0, examples=[70])
    percentage: float = Field(ge=0, le=100, examples=[58.33])


class DailyActivity(BaseModel):
    """Número de notas creadas en un día (UTC)."""

    date: date
    count: int = Field(ge=0)


class NoteStatsResponse(BaseModel):
    """Métricas agregadas listas para alimentar gráficas."""

    total_notes: int = Field(ge=0)
    by_category: list[CategoryStat]
    activity: list[DailyActivity]
    most_used_category: str | None = Field(
        description="Categoría con más notas; null si no hay notas en el alcance."
    )
