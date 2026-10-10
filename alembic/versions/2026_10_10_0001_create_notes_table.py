"""create notes table

Revision ID: 0001
Revises:
Create Date: 2026-10-10 00:00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "notes",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("category", sa.String(length=50), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.CheckConstraint("CHAR_LENGTH(TRIM(title)) > 0", name="ck_notes_title_not_blank"),
        sa.CheckConstraint("CHAR_LENGTH(TRIM(content)) > 0", name="ck_notes_content_not_blank"),
        sa.CheckConstraint("CHAR_LENGTH(TRIM(category)) > 0", name="ck_notes_category_not_blank"),
        sa.PrimaryKeyConstraint("id"),
        mysql_engine="InnoDB",
        mysql_charset="utf8mb4",
        mysql_collate="utf8mb4_unicode_ci",
    )
    op.create_index("ix_notes_created_at", "notes", ["created_at"], unique=False)
    op.create_index(
        "ix_notes_category_created_at", "notes", ["category", "created_at"], unique=False
    )


def downgrade() -> None:
    op.drop_index("ix_notes_category_created_at", table_name="notes")
    op.drop_index("ix_notes_created_at", table_name="notes")
    op.drop_table("notes")
