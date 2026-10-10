"""Motor de SQLAlchemy, fábrica de sesiones y dependencia de FastAPI."""

from collections.abc import Iterator

from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import get_settings

# Todas las fechas se almacenan y se interpretan en UTC. Fijar la zona horaria de
# cada conexión hace que CURRENT_TIMESTAMP y DATE() sean independientes de la
# configuración del servidor MySQL.
SESSION_TIME_ZONE = "+00:00"


class Base(DeclarativeBase):
    """Clase base de los modelos de persistencia."""


def create_db_engine(url: URL) -> Engine:
    """Crea un motor configurado para MySQL.

    - `pool_pre_ping` descarta conexiones cerradas por el servidor (p. ej. `wait_timeout`).
    - `pool_recycle` renueva conexiones antes de que MySQL las cierre por inactividad.
    - `connect_timeout` evita que una petición quede bloqueada si MySQL no responde.
    """
    return create_engine(
        url,
        pool_pre_ping=True,
        pool_recycle=3600,
        connect_args={
            "connect_timeout": 5,
            "init_command": f"SET time_zone = '{SESSION_TIME_ZONE}'",
        },
    )


engine = create_db_engine(get_settings().database_url())
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def get_db() -> Iterator[Session]:
    """Proporciona una sesión nueva por petición y la cierra al terminar.

    Cada petición obtiene su propia sesión, por lo que nunca se comparte una
    sesión entre peticiones concurrentes.
    """
    with SessionLocal() as session:
        yield session


def check_database_connection(db_engine: Engine = engine) -> None:
    """Ejecuta una consulta trivial para comprobar la conexión con MySQL."""
    with db_engine.connect() as connection:
        connection.execute(text("SELECT 1"))
