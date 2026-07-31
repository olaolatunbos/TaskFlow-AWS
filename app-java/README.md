# app-java

A Spring Boot port of the Flask API in [`app/`](../app). Same routes, same JSON
shapes, same status codes, same in-memory (non-persistent) task store.

It listens on **8080**, Spring Boot's default — unlike the Flask app, which uses
`3000`. See [Port](#port) for what that means for deployment.

## Routes

| Method | Path          | Response                                                     |
| ------ | ------------- | ------------------------------------------------------------ |
| GET    | `/`           | The task UI (Thymeleaf render of `templates/index.html`)      |
| GET    | `/health`     | `200 {"status": "ok"}`                                        |
| GET    | `/tasks`      | `200 [ ...tasks ]` in creation order                           |
| POST   | `/tasks`      | `201 {task}`, or `400` if the body or `title` is missing       |
| GET    | `/tasks/{id}` | `200 {task}` or `404`                                          |
| PUT    | `/tasks/{id}` | `200 {task}` (partial update) or `404`                         |
| DELETE | `/tasks/{id}` | `200 {"result": true}` or `404`                                |

A task is `{"id", "title", "description", "completed"}`. `description` defaults
to `""`; `completed` starts `false`.

## Commands

Requires JDK 21 and Maven. Run from this directory:

```bash
mvn spring-boot:run     # run locally on :8080
mvn test                # run the test suite
mvn verify              # tests + package
mvn clean package       # build target/app.jar
java -jar target/app.jar
```

No JDK locally? Everything can go through Docker instead:

```bash
docker run --rm -v "$PWD":/project -w /project maven:3.9-eclipse-temurin-21 mvn -B test
docker build -t taskflow-java .
docker run --rm -p 8080:8080 taskflow-java
```

## Layout

```
src/main/java/com/taskflow/
  TaskflowApplication.java     entry point
  model/Task.java              the task record
  model/TaskRequest.java       incoming payload; boxed fields make PUT a partial update
  store/TaskStore.java         in-memory store (the Flask `tasks` dict)
  web/IndexController.java     GET /
  web/HealthController.java    GET /health
  web/TaskController.java      /tasks CRUD
  web/ApiExceptionHandler.java errors as {"error": "..."}
src/main/resources/
  application.properties       port 8080, /static/** path pattern
  templates/index.html         copied verbatim from the Flask app
  static/                      style.css, script.js, images/ — copied verbatim
src/test/java/com/taskflow/
  TaskflowApplicationTests.java  MockMvc tests, 1:1 with app/tests/test_app.py
```

`spring.mvc.static-path-pattern=/static/**` is what lets `index.html` and
`script.js` be byte-identical to the Flask versions — Spring Boot would
otherwise serve them from `/` rather than `/static/`.

## Container

Multi-stage like the Python image: build on `maven:3.9-eclipse-temurin-21`,
run on `gcr.io/distroless/java21-debian12:nonroot` as UID `65532`, exposing
`8080`. The distroless base has no shell.

## Port

`server.port=8080` in `application.properties`, with a matching `EXPOSE` in the
Dockerfile. No rebuild is needed to change it — Spring Boot binds the `SERVER_PORT`
environment variable automatically:

```bash
docker run --rm -e SERVER_PORT=3000 -p 3000:3000 taskflow-java
```

That override is what a deployment would use, because the Terraform
`container_port` variable is `3000` and is shared by both environments *and* by
the Flask app. Changing that variable to `8080` would break the Python
deployment; overriding `SERVER_PORT` per task definition would not.

## Not wired up

This folder is standalone. The Terraform in [`terraform/`](../terraform) and the
workflows in [`.github/workflows/`](../.github/workflows) still build and deploy
[`app/`](../app) only — CI triggers on `app/**` paths and the ECR repos hold the
Python image. Pointing a workspace at this app means adding a matching CI job
and repository, not just changing the image tag.
