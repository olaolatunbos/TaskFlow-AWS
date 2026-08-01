import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import app as app_module


@pytest.fixture
def client():
    app_module.tasks.clear()
    app_module.app.config["TESTING"] = True
    with app_module.app.test_client() as client:
        yield client


def create_task(client, title="Test task", description="Test description"):
    return client.post("/tasks", json={"title": title, "description": description})


def test_index_returns_200(client):
    response = client.get("/")
    assert response.status_code == 200


def test_health_returns_200(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_get_tasks_empty(client):
    response = client.get("/tasks")
    assert response.status_code == 200
    assert response.get_json() == []


def test_create_task(client):
    response = create_task(client, title="Buy milk", description="2%")
    assert response.status_code == 201
    body = response.get_json()
    assert body["title"] == "Buy milk"
    assert body["description"] == "2%"
    assert body["completed"] is False
    assert "id" in body


def test_create_task_missing_title(client):
    response = client.post("/tasks", json={"description": "no title"})
    assert response.status_code == 400


def test_create_task_missing_body(client):
    response = client.post("/tasks", data="", content_type="application/json")
    assert response.status_code == 400


def test_create_task_defaults_description(client):
    response = client.post("/tasks", json={"title": "No description"})
    assert response.status_code == 201
    assert response.get_json()["description"] == ""


def test_get_tasks_after_create(client):
    create_task(client)
    response = client.get("/tasks")
    assert response.status_code == 200
    assert len(response.get_json()) == 1


def test_get_task_by_id(client):
    task_id = create_task(client).get_json()["id"]
    response = client.get(f"/tasks/{task_id}")
    assert response.status_code == 200
    assert response.get_json()["id"] == task_id


def test_get_task_not_found(client):
    response = client.get("/tasks/does-not-exist")
    assert response.status_code == 404


def test_update_task(client):
    task_id = create_task(client).get_json()["id"]
    response = client.put(
        f"/tasks/{task_id}",
        json={"title": "Updated", "completed": True},
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["title"] == "Updated"
    assert body["completed"] is True


def test_update_task_partial(client):
    task_id = create_task(
        client, title="Original", description="Original desc"
    ).get_json()["id"]
    response = client.put(f"/tasks/{task_id}", json={"completed": True})
    assert response.status_code == 200
    body = response.get_json()
    assert body["title"] == "Original"
    assert body["description"] == "Original desc"
    assert body["completed"] is True


def test_update_task_not_found(client):
    response = client.put("/tasks/does-not-exist", json={"title": "x"})
    assert response.status_code == 404


def test_delete_task(client):
    task_id = create_task(client).get_json()["id"]
    response = client.delete(f"/tasks/{task_id}")
    assert response.status_code == 200
    assert response.get_json() == {"result": True}
    assert client.get(f"/tasks/{task_id}").status_code == 404


def test_delete_task_not_found(client):
    response = client.delete("/tasks/does-not-exist")
    assert response.status_code == 404
