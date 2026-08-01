import uuid
from flask import Flask, request, jsonify, abort, render_template

app = Flask(__name__, template_folder="templates", static_folder="static")


tasks = {}

STATUSES = ("todo", "in_progress", "done")
STAGES = ("not_started", "in_research", "on_track", "complete")
PRIORITIES = ("low", "medium", "high")


def _one_of(value, allowed, fallback):
    return value if value in allowed else fallback


def _as_count(value, fallback=0):
    try:
        count = int(value)
    except (TypeError, ValueError):
        return fallback
    return count if count >= 0 else fallback


def _as_assignees(value, fallback=None):
    if not isinstance(value, list):
        return list(fallback or [])
    return [str(name).strip() for name in value if str(name).strip()][:6]


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/tasks", methods=["GET"])
def get_tasks():
    return jsonify(list(tasks.values()))


@app.route("/tasks", methods=["POST"])
def create_task():
    data = request.get_json(silent=True)
    if not data or "title" not in data:
        abort(400, description="Missing task title")

    completed = bool(data.get("completed", False))
    status = _one_of(data.get("status"), STATUSES, "done" if completed else "todo")

    task_id = str(uuid.uuid4())
    task = {
        "id": task_id,
        "title": data["title"],
        "description": data.get("description", ""),
        "completed": completed or status == "done",
        "status": status,
        "stage": _one_of(
            data.get("stage"), STAGES, "complete" if status == "done" else "not_started"
        ),
        "priority": _one_of(data.get("priority"), PRIORITIES, "medium"),
        "due_date": data.get("due_date", ""),
        "assignees": _as_assignees(data.get("assignees")),
        "comments": _as_count(data.get("comments")),
        "links": _as_count(data.get("links")),
        "subtasks_done": _as_count(data.get("subtasks_done")),
        "subtasks_total": _as_count(data.get("subtasks_total")),
    }
    tasks[task_id] = task
    return jsonify(task), 201


@app.route("/tasks/<task_id>", methods=["GET"])
def get_task(task_id):
    task = tasks.get(task_id)
    if not task:
        abort(404, description="Task not found")
    return jsonify(task)


@app.route("/tasks/<task_id>", methods=["PUT"])
def update_task(task_id):
    if task_id not in tasks:
        abort(404, description="Task not found")
    data = request.get_json(silent=True) or {}
    task = tasks[task_id]

    task["title"] = data.get("title", task["title"])
    task["description"] = data.get("description", task["description"])
    task["due_date"] = data.get("due_date", task["due_date"])
    task["priority"] = _one_of(data.get("priority"), PRIORITIES, task["priority"])
    task["stage"] = _one_of(data.get("stage"), STAGES, task["stage"])
    task["assignees"] = _as_assignees(data.get("assignees"), task["assignees"])
    task["comments"] = _as_count(data.get("comments"), task["comments"])
    task["links"] = _as_count(data.get("links"), task["links"])
    task["subtasks_done"] = _as_count(data.get("subtasks_done"), task["subtasks_done"])
    task["subtasks_total"] = _as_count(
        data.get("subtasks_total"), task["subtasks_total"]
    )

    # `status` (board column) and `completed` are two views of the same thing, so
    # whichever one the caller sent wins and the other is kept consistent with it.
    if "status" in data:
        task["status"] = _one_of(data.get("status"), STATUSES, task["status"])
        task["completed"] = task["status"] == "done"
    elif "completed" in data:
        task["completed"] = bool(data["completed"])
        task["status"] = "done" if task["completed"] else "todo"

    tasks[task_id] = task
    return jsonify(task)


@app.route("/tasks/reorder", methods=["POST"])
def reorder_tasks():
    data = request.get_json(silent=True) or {}
    order = data.get("order")
    if not isinstance(order, list):
        abort(400, description="Missing task order")

    reordered = {task_id: tasks[task_id] for task_id in order if task_id in tasks}
    for task_id, task in tasks.items():
        reordered.setdefault(task_id, task)

    tasks.clear()
    tasks.update(reordered)
    return jsonify(list(tasks.values()))


@app.route("/tasks/<task_id>", methods=["DELETE"])
def delete_task(task_id):
    if task_id not in tasks:
        abort(404, description="Task not found")
    del tasks[task_id]
    return jsonify({"result": True})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000, debug=True)
