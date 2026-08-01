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


def test_create_task_board_defaults(client):
    body = create_task(client).get_json()
    assert body["status"] == "todo"
    assert body["stage"] == "not_started"
    assert body["priority"] == "medium"
    assert body["due_date"] == ""
    assert body["assignees"] == []
    assert body["comments"] == 0
    assert body["links"] == 0
    assert body["subtasks_done"] == 0
    assert body["subtasks_total"] == 0


def test_create_task_with_board_fields(client):
    response = client.post(
        "/tasks",
        json={
            "title": "Design Homepage Wireframe",
            "status": "in_progress",
            "stage": "on_track",
            "priority": "high",
            "due_date": "2023-11-02",
            "assignees": ["Ada Lovelace", " ", "Rae Mensah"],
            "subtasks_done": 1,
            "subtasks_total": 3,
        },
    )
    assert response.status_code == 201
    body = response.get_json()
    assert body["status"] == "in_progress"
    assert body["stage"] == "on_track"
    assert body["priority"] == "high"
    assert body["due_date"] == "2023-11-02"
    assert body["assignees"] == ["Ada Lovelace", "Rae Mensah"]
    assert body["subtasks_done"] == 1
    assert body["subtasks_total"] == 3
    assert body["completed"] is False


def test_create_task_rejects_unknown_enum_values(client):
    body = client.post(
        "/tasks",
        json={"title": "x", "status": "archived", "priority": "urgent", "stage": "wip"},
    ).get_json()
    assert body["status"] == "todo"
    assert body["priority"] == "medium"
    assert body["stage"] == "not_started"


def test_create_task_completed_implies_done_status(client):
    body = create_task(client)
    assert body.get_json()["status"] == "todo"
    done = client.post("/tasks", json={"title": "Shipped", "completed": True})
    assert done.get_json()["status"] == "done"
    assert done.get_json()["stage"] == "complete"


def test_update_status_syncs_completed(client):
    task_id = create_task(client).get_json()["id"]
    body = client.put(f"/tasks/{task_id}", json={"status": "done"}).get_json()
    assert body["completed"] is True

    body = client.put(f"/tasks/{task_id}", json={"status": "in_progress"}).get_json()
    assert body["completed"] is False


def test_update_completed_syncs_status(client):
    task_id = create_task(client).get_json()["id"]
    body = client.put(f"/tasks/{task_id}", json={"completed": True}).get_json()
    assert body["status"] == "done"

    body = client.put(f"/tasks/{task_id}", json={"completed": False}).get_json()
    assert body["status"] == "todo"


def test_update_task_keeps_board_fields(client):
    task_id = client.post(
        "/tasks", json={"title": "x", "priority": "high", "due_date": "2023-11-02"}
    ).get_json()["id"]
    body = client.put(f"/tasks/{task_id}", json={"title": "y"}).get_json()
    assert body["priority"] == "high"
    assert body["due_date"] == "2023-11-02"


def test_update_task_negative_counts_are_ignored(client):
    task_id = client.post("/tasks", json={"title": "x", "comments": 4}).get_json()["id"]
    body = client.put(f"/tasks/{task_id}", json={"comments": -1}).get_json()
    assert body["comments"] == 4


def test_reorder_tasks(client):
    first = create_task(client, title="First").get_json()["id"]
    second = create_task(client, title="Second").get_json()["id"]
    third = create_task(client, title="Third").get_json()["id"]

    response = client.post("/tasks/reorder", json={"order": [third, first]})
    assert response.status_code == 200
    assert [task["id"] for task in response.get_json()] == [third, first, second]


def test_reorder_ignores_unknown_ids(client):
    task_id = create_task(client).get_json()["id"]
    response = client.post("/tasks/reorder", json={"order": ["nope", task_id]})
    assert response.status_code == 200
    assert [task["id"] for task in response.get_json()] == [task_id]


def test_reorder_requires_order_list(client):
    assert client.post("/tasks/reorder", json={}).status_code == 400
    assert client.post("/tasks/reorder", json={"order": "abc"}).status_code == 400
