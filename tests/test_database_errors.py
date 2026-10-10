"""Errores de conexión y de acceso a datos. No necesitan un servidor MySQL."""

from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.engine import URL
from sqlalchemy.exc import ProgrammingError
from sqlalchemy.orm import Session, sessionmaker

from app.core.database import create_db_engine, get_db
from app.main import DB_ERROR_MESSAGE, DB_UNAVAILABLE_MESSAGE, app
from app.services import note_service

SECRET_PASSWORD = "Sup3r-S3cret!"
ENDPOINTS = ["/api/v1/notes", "/api/v1/notes/stats"]


@pytest.fixture
def unreachable_db_client() -> Iterator[TestClient]:
    """Cliente cuya base de datos apunta a un puerto donde no escucha MySQL."""
    url = URL.create(
        "mysql+pymysql",
        username="root",
        password=SECRET_PASSWORD,
        host="127.0.0.1",
        port=1,
        database="notes_test_db",
    )
    engine = create_db_engine(url)
    session_factory = sessionmaker(bind=engine)

    def override_get_db() -> Iterator[Session]:
        with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()
    engine.dispose()


@pytest.mark.parametrize("endpoint", ENDPOINTS)
def test_unavailable_database_returns_503_without_sensitive_data(
    unreachable_db_client: TestClient, endpoint: str
) -> None:
    response = unreachable_db_client.get(endpoint)

    assert response.status_code == 503
    assert response.json() == {"detail": DB_UNAVAILABLE_MESSAGE}
    for sensitive in (SECRET_PASSWORD, "127.0.0.1", "root", "pymysql"):
        assert sensitive not in response.text


def test_unexpected_database_error_returns_500_without_details(
    unreachable_db_client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    def failing_list_notes(*_: object, **__: object) -> None:
        raise ProgrammingError("SELECT * FROM notes", {}, Exception("Table 'notes' doesn't exist"))

    monkeypatch.setattr(note_service, "list_notes", failing_list_notes)

    response = unreachable_db_client.get("/api/v1/notes")

    assert response.status_code == 500
    assert response.json() == {"detail": DB_ERROR_MESSAGE}
    assert "notes' doesn't exist" not in response.text
