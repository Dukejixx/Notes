"""Pruebas de GET /api/v1/notes/stats."""

from datetime import datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from tests.conftest import add_note

URL = "/api/v1/notes/stats"


def _day(day: int, hour: int = 12, minute: int = 0, second: int = 0) -> datetime:
    return datetime(2026, 10, day, hour, minute, second)


def test_empty_database_returns_valid_response(client: TestClient) -> None:
    response = client.get(URL)

    assert response.status_code == 200
    assert response.json() == {
        "total_notes": 0,
        "by_category": [],
        "activity": [],
        "most_used_category": None,
    }


def test_counts_and_percentages_match_stored_notes(client: TestClient, db_session: Session) -> None:
    for category in ["Estudio", "Estudio", "Personal"]:
        add_note(db_session, _day(1), category=category)

    body = client.get(URL).json()

    assert body["total_notes"] == 3
    assert body["by_category"] == [
        {"category": "Estudio", "count": 2, "percentage": 66.67},
        {"category": "Personal", "count": 1, "percentage": 33.33},
    ]
    assert body["most_used_category"] == "Estudio"


def test_most_used_category_tie_is_resolved_alphabetically(
    client: TestClient, db_session: Session
) -> None:
    for category in ["Trabajo", "Personal", "Trabajo", "Personal"]:
        add_note(db_session, _day(1), category=category)

    body = client.get(URL).json()

    assert [stat["category"] for stat in body["by_category"]] == ["Personal", "Trabajo"]
    assert [stat["percentage"] for stat in body["by_category"]] == [50.0, 50.0]
    assert body["most_used_category"] == "Personal"


def test_activity_without_dates_fills_gaps_between_first_and_last_day(
    client: TestClient, db_session: Session
) -> None:
    add_note(db_session, _day(1))
    add_note(db_session, _day(1, hour=23))
    add_note(db_session, _day(4))

    activity = client.get(URL).json()["activity"]

    assert activity == [
        {"date": "2026-10-01", "count": 2},
        {"date": "2026-10-02", "count": 0},
        {"date": "2026-10-03", "count": 0},
        {"date": "2026-10-04", "count": 1},
    ]


def test_date_range_filters_all_metrics_inclusively(
    client: TestClient, db_session: Session
) -> None:
    add_note(db_session, _day(1, hour=23, minute=59, second=59), category="Fuera")
    add_note(db_session, _day(2, hour=0), category="Estudio")  # Inicio del rango.
    add_note(db_session, _day(3), category="Personal")
    add_note(db_session, _day(4, hour=23, minute=59, second=59), category="Estudio")  # Fin.
    add_note(db_session, _day(5, hour=0), category="Fuera")

    body = client.get(URL, params={"from_date": "2026-10-02", "to_date": "2026-10-04"}).json()

    assert body["total_notes"] == 3
    assert body["by_category"] == [
        {"category": "Estudio", "count": 2, "percentage": 66.67},
        {"category": "Personal", "count": 1, "percentage": 33.33},
    ]
    assert body["most_used_category"] == "Estudio"
    assert body["activity"] == [
        {"date": "2026-10-02", "count": 1},
        {"date": "2026-10-03", "count": 1},
        {"date": "2026-10-04", "count": 1},
    ]


def test_explicit_range_includes_days_without_notes(
    client: TestClient, db_session: Session
) -> None:
    add_note(db_session, _day(3))

    activity = client.get(URL, params={"from_date": "2026-10-01", "to_date": "2026-10-05"}).json()[
        "activity"
    ]

    assert [entry["date"] for entry in activity] == [f"2026-10-0{day}" for day in range(1, 6)]
    assert [entry["count"] for entry in activity] == [0, 0, 1, 0, 0]


def test_only_from_date_filters_from_that_day(client: TestClient, db_session: Session) -> None:
    add_note(db_session, _day(1))
    add_note(db_session, _day(3))
    add_note(db_session, _day(5))

    body = client.get(URL, params={"from_date": "2026-10-03"}).json()

    assert body["total_notes"] == 2
    assert [entry["date"] for entry in body["activity"]] == [
        "2026-10-03",
        "2026-10-04",
        "2026-10-05",
    ]


def test_only_to_date_filters_until_that_day(client: TestClient, db_session: Session) -> None:
    add_note(db_session, _day(1))
    add_note(db_session, _day(3))
    add_note(db_session, _day(5))

    body = client.get(URL, params={"to_date": "2026-10-03"}).json()

    assert body["total_notes"] == 2
    assert body["activity"][-1] == {"date": "2026-10-03", "count": 1}


def test_range_without_notes_returns_empty_response(
    client: TestClient, db_session: Session
) -> None:
    add_note(db_session, _day(1))

    body = client.get(URL, params={"from_date": "2026-10-10", "to_date": "2026-10-12"}).json()

    assert body == {
        "total_notes": 0,
        "by_category": [],
        "activity": [],
        "most_used_category": None,
    }


def test_metrics_share_the_same_scope(client: TestClient, db_session: Session) -> None:
    for day, category in [(1, "A"), (2, "B"), (2, "C"), (6, "A")]:
        add_note(db_session, _day(day), category=category)

    body = client.get(URL, params={"from_date": "2026-10-01", "to_date": "2026-10-03"}).json()

    assert body["total_notes"] == sum(stat["count"] for stat in body["by_category"])
    assert body["total_notes"] == sum(entry["count"] for entry in body["activity"])
    assert sum(stat["percentage"] for stat in body["by_category"]) == pytest.approx(100, abs=0.05)


@pytest.mark.parametrize(
    ("params", "message"),
    [
        ({"from_date": "2026-10-05", "to_date": "2026-10-01"}, "from_date"),
        ({"from_date": "2025-01-01", "to_date": "2026-01-02"}, "366"),
    ],
)
def test_rejects_invalid_ranges(client: TestClient, params: dict[str, str], message: str) -> None:
    response = client.get(URL, params=params)

    assert response.status_code == 422
    assert message in response.json()["detail"]


def test_accepts_maximum_range(client: TestClient) -> None:
    response = client.get(URL, params={"from_date": "2025-01-01", "to_date": "2026-01-01"})

    assert response.status_code == 200


@pytest.mark.parametrize(
    "params",
    [{"from_date": "2026-13-01"}, {"to_date": "ayer"}, {"from_date": "2026-02-30"}],
)
def test_rejects_invalid_dates(client: TestClient, params: dict[str, str]) -> None:
    response = client.get(URL, params=params)

    assert response.status_code == 422
