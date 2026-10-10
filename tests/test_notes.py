"""Pruebas de GET /api/v1/notes."""

from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.note import Note
from tests.conftest import add_note

URL = "/api/v1/notes"
PUBLIC_FIELDS = {"id", "title", "content", "category", "created_at", "updated_at"}
BASE_TIME = datetime(2026, 10, 1, 12, 0, 0)


def test_empty_list(client: TestClient) -> None:
    response = client.get(URL)

    assert response.status_code == 200
    assert response.json() == {"items": [], "total": 0, "page": 1, "limit": 10}


def test_returns_expected_fields(client: TestClient, db_session: Session) -> None:
    note = add_note(
        db_session,
        BASE_TIME,
        category="Estudio",
        title="Aprender FastAPI",
        content="Estudiar endpoints y dependencias",
    )

    body = client.get(URL).json()

    assert body["total"] == 1
    item = body["items"][0]
    assert set(item) == PUBLIC_FIELDS
    assert item == {
        "id": note.id,
        "title": "Aprender FastAPI",
        "content": "Estudiar endpoints y dependencias",
        "category": "Estudio",
        "created_at": "2026-10-01T12:00:00",
        "updated_at": "2026-10-01T12:00:00",
    }


def test_orders_by_creation_date_descending(client: TestClient, db_session: Session) -> None:
    oldest = add_note(db_session, BASE_TIME)
    newest = add_note(db_session, BASE_TIME + timedelta(days=2))
    middle = add_note(db_session, BASE_TIME + timedelta(days=1))
    # Misma fecha que `newest`: el id mayor va primero para que el orden sea estable.
    tie = add_note(db_session, BASE_TIME + timedelta(days=2))

    ids = [item["id"] for item in client.get(URL).json()["items"]]

    assert ids == [tie.id, newest.id, middle.id, oldest.id]


def test_pagination(client: TestClient, db_session: Session) -> None:
    notes = [add_note(db_session, BASE_TIME + timedelta(minutes=i)) for i in range(25)]
    expected_ids = [note.id for note in reversed(notes)]

    pages = {page: client.get(URL, params={"page": page, "limit": 10}).json() for page in (1, 2, 3)}

    assert [len(pages[page]["items"]) for page in (1, 2, 3)] == [10, 10, 5]
    assert all(pages[page]["total"] == 25 for page in pages)
    assert pages[2]["page"] == 2
    assert pages[2]["limit"] == 10
    received_ids = [item["id"] for page in (1, 2, 3) for item in pages[page]["items"]]
    assert received_ids == expected_ids


def test_page_beyond_last_returns_empty_items(client: TestClient, db_session: Session) -> None:
    add_note(db_session, BASE_TIME)

    body = client.get(URL, params={"page": 5, "limit": 10}).json()

    assert body == {"items": [], "total": 1, "page": 5, "limit": 10}


def test_maximum_limit_is_accepted(client: TestClient) -> None:
    response = client.get(URL, params={"limit": 100})

    assert response.status_code == 200
    assert response.json()["limit"] == 100


@pytest.mark.parametrize(
    "params",
    [
        {"page": 0},
        {"page": -1},
        {"page": "abc"},
        {"limit": 0},
        {"limit": 101},
        {"limit": "diez"},
    ],
)
def test_rejects_invalid_parameters(client: TestClient, params: dict[str, object]) -> None:
    response = client.get(URL, params=params)

    assert response.status_code == 422


def test_database_assigns_creation_date_in_utc(client: TestClient, db_session: Session) -> None:
    db_session.add(Note(title="Sin fecha", content="La asigna MySQL", category="Personal"))
    db_session.commit()

    created_at = datetime.fromisoformat(client.get(URL).json()["items"][0]["created_at"])

    now_utc = datetime.now(UTC).replace(tzinfo=None)
    assert abs(now_utc - created_at) < timedelta(minutes=1)
