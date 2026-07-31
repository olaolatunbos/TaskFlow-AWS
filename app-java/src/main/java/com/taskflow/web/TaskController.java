package com.taskflow.web;

import com.taskflow.model.Task;
import com.taskflow.model.TaskRequest;
import com.taskflow.store.TaskStore;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/tasks")
public class TaskController {

    private final TaskStore store;

    public TaskController(TaskStore store) {
        this.store = store;
    }

    @GetMapping
    public List<Task> getTasks() {
        return store.findAll();
    }

    @PostMapping
    public ResponseEntity<Task> createTask(@RequestBody TaskRequest body) {
        if (body == null || body.title() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Missing task title");
        }
        Task task = new Task(
                UUID.randomUUID().toString(),
                body.title(),
                body.description() == null ? "" : body.description(),
                false);
        store.save(task);
        return ResponseEntity.status(HttpStatus.CREATED).body(task);
    }

    @GetMapping("/{taskId}")
    public Task getTask(@PathVariable String taskId) {
        return store.find(taskId).orElseThrow(TaskController::notFound);
    }

    @PutMapping("/{taskId}")
    public Task updateTask(@PathVariable String taskId, @RequestBody TaskRequest body) {
        Task existing = store.find(taskId).orElseThrow(TaskController::notFound);
        Task updated = new Task(
                existing.id(),
                body.title() == null ? existing.title() : body.title(),
                body.description() == null ? existing.description() : body.description(),
                body.completed() == null ? existing.completed() : body.completed());
        store.save(updated);
        return updated;
    }

    @DeleteMapping("/{taskId}")
    public Map<String, Boolean> deleteTask(@PathVariable String taskId) {
        if (!store.delete(taskId)) {
            throw notFound();
        }
        return Map.of("result", true);
    }

    private static ResponseStatusException notFound() {
        return new ResponseStatusException(HttpStatus.NOT_FOUND, "Task not found");
    }
}
