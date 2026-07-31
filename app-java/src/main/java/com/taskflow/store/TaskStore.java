package com.taskflow.store;

import com.taskflow.model.Task;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * In-memory task store — the equivalent of the module-level {@code tasks} dict
 * in the Flask app. State is lost on restart. Insertion order is preserved so
 * {@code GET /tasks} lists tasks in creation order, as the Python dict did.
 */
@Component
public class TaskStore {

    private final Map<String, Task> tasks = Collections.synchronizedMap(new LinkedHashMap<>());

    public List<Task> findAll() {
        synchronized (tasks) {
            return new ArrayList<>(tasks.values());
        }
    }

    public Optional<Task> find(String id) {
        return Optional.ofNullable(tasks.get(id));
    }

    public void save(Task task) {
        tasks.put(task.id(), task);
    }

    public boolean delete(String id) {
        return tasks.remove(id) != null;
    }

    /** Resets the store. Tests call this the way the pytest fixture cleared the dict. */
    public void clear() {
        tasks.clear();
    }
}
