"""Modelo de persistencia de la tabla `notes`."""

from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, Index, Integer, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base

TITLE_MAX_LENGTH = 200
CATEGORY_MAX_LENGTH = 50


class Note(Base):
    """Nota personal.

    Las fechas se guardan como DATETIME sin zona horaria y siempre en UTC
    (ver `SESSION_TIME_ZONE` en `app.core.database`).
    """

    __tablename__ = "notes"
    __table_args__ = (
        CheckConstraint("CHAR_LENGTH(TRIM(title)) > 0", name="ck_notes_title_not_blank"),
        CheckConstraint("CHAR_LENGTH(TRIM(content)) > 0", name="ck_notes_content_not_blank"),
        CheckConstraint("CHAR_LENGTH(TRIM(category)) > 0", name="ck_notes_category_not_blank"),
        # Orden del listado y filtro por rango de fechas de las estadísticas.
        Index("ix_notes_created_at", "created_at"),
        # Índice de cobertura para agrupar por categoría dentro de un rango de fechas.
        Index("ix_notes_category_created_at", "category", "created_at"),
        {
            "mysql_engine": "InnoDB",
            "mysql_charset": "utf8mb4",
            "mysql_collate": "utf8mb4_unicode_ci",
        },
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(TITLE_MAX_LENGTH), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(String(CATEGORY_MAX_LENGTH), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
    )

    def __repr__(self) -> str:
        return f"Note(id={self.id!r}, category={self.category!r})"
