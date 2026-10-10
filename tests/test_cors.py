"""Política CORS para el frontend web. No necesita un servidor MySQL."""

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def _preflight(origin: str, method: str = "GET") -> dict[str, str]:
    response = client.options(
        "/api/v1/notes",
        headers={"Origin": origin, "Access-Control-Request-Method": method},
    )
    return dict(response.headers) | {"status": str(response.status_code)}


@pytest.mark.parametrize(
    "origin", ["http://localhost:53421", "http://127.0.0.1:8080", "http://localhost"]
)
def test_allows_local_origins(origin: str) -> None:
    headers = _preflight(origin)

    assert headers["status"] == "200"
    assert headers["access-control-allow-origin"] == origin


@pytest.mark.parametrize(
    "origin", ["http://evil.example", "http://localhost.evil.example", "http://192.168.1.10:8080"]
)
def test_rejects_other_origins(origin: str) -> None:
    headers = _preflight(origin)

    assert headers["status"] == "400"
    assert "access-control-allow-origin" not in headers


def test_only_allows_get() -> None:
    assert _preflight("http://localhost:53421", method="DELETE")["status"] == "400"
