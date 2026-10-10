"""Entorno de Alembic: obtiene la conexión de la configuración de la aplicación."""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import Connection

from app.core.config import get_settings
from app.core.database import Base, create_db_engine
from app.models import Note  # noqa: F401  (registra los modelos en Base.metadata)

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Genera el SQL sin conectarse (`alembic upgrade head --sql`)."""
    context.configure(
        dialect_name="mysql",
        target_metadata=target_metadata,
        literal_binds=True,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def _run_with_connection(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Aplica las migraciones sobre MySQL.

    Si quien invoca Alembic proporciona una conexión (por ejemplo, las pruebas
    sobre la base de datos aislada), se usa esa; si no, se usa la de `.env`.
    """
    connection = config.attributes.get("connection")
    if connection is not None:
        _run_with_connection(connection)
        return

    engine = create_db_engine(get_settings().database_url())
    try:
        with engine.connect() as new_connection:
            _run_with_connection(new_connection)
    finally:
        engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
