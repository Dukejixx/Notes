"""Fixtures de pruebas sobre una base de datos MySQL aislada.

Las pruebas nunca usan `DB_NAME`: se conectan a `TEST_DB_NAME` (por defecto
`notes_test_db`), recrean su esquema con las migraciones de Alembic y vacían la
tabla antes de cada prueba.
"""

from collections.abc import Iterator
from datetime import datetime
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import Settings
from app.core.database import create_db_engine, get_db
from app.main import app
from app.models.note import Note

PROJECT_ROOT = Path(__file__).resolve().parent.parent


class TestSettings(Settings):
    """Configuración de la aplicación más el nombre de la base de datos de pruebas."""

    test_db_name: str = "notes_test_db"


def _test_database_name(settings: TestSettings) -> str:
    """Valida que la base de pruebas no pueda confundirse con la de desarrollo."""
    name = settings.test_db_name
    if name == settings.db_name or "test" not in name.lower():
        pytest.exit(
            f"TEST_DB_NAME={name!r} no es seguro: debe ser distinto de DB_NAME "
            "y contener 'test'. Se cancelan las pruebas para proteger tus datos.",
            returncode=2,
        )
    return name


@pytest.fixture(scope="session")
def test_engine() -> Iterator[Engine]:
    settings = TestSettings()
    database = _test_database_name(settings)
    engine = create_db_engine(settings.database_url(database))
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    except SQLAlchemyError as exc:
        engine.dispose()
        pytest.skip(
            f"MySQL no disponible para la base de pruebas {database!r} "
            f"({type(exc).__name__}). Consulta la sección de pruebas del README."
        )

    alembic_config = Config(str(PROJECT_ROOT / "alembic.ini"))
    alembic_config.set_main_option("script_location", str(PROJECT_ROOT / "alembic"))
    with engine.begin() as connection:
        alembic_config.attributes["connection"] = connection
        command.downgrade(alembic_config, "base")
        command.upgrade(alembic_config, "head")

    yield engine
    engine.dispose()


@pytest.fixture
def db_session(test_engine: Engine) -> Iterator[Session]:
    """Sesión sobre la base de pruebas con la tabla `notes` vacía."""
    with test_engine.begin() as connection:
        connection.execute(text("TRUNCATE TABLE notes"))
    session_factory = sessionmaker(bind=test_engine, autoflush=False, expire_on_commit=False)
    with session_factory() as session:
        yield session


@pytest.fixture
def client(test_engine: Engine, db_session: Session) -> Iterator[TestClient]:
    """Cliente HTTP cuya dependencia `get_db` apunta a la base de pruebas."""
    session_factory = sessionmaker(bind=test_engine, autoflush=False, expire_on_commit=False)

    def override_get_db() -> Iterator[Session]:
        with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db
    # Sin bloque `with` para no ejecutar el lifespan, que usa la base de desarrollo.
    yield TestClient(app)
    app.dependency_overrides.clear()


def add_note(
    session: Session,
    created_at: datetime,
    category: str = "Estudio",
    title: str = "Nota",
    content: str = "Contenido",
) -> Note:
    """Inserta una nota con una fecha de creación controlada (UTC)."""
    note = Note(
        title=title,
        content=content,
        category=category,
        created_at=created_at,
        updated_at=created_at,
    )
    session.add(note)
    session.commit()
    return note
