package com.taskflow;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.taskflow.store.TaskStore;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
class TaskflowApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TaskStore store;

    /** The store is shared global state, so reset it the way the pytest fixture did. */
    @BeforeEach
    void resetStore() {
        store.clear();
    }

    private MvcResult postTask(String title, String description) throws Exception {
        String body = objectMapper.writeValueAsString(Map.of("title", title, "description", description));
        return mockMvc.perform(post("/tasks").contentType(MediaType.APPLICATION_JSON).content(body))
                .andReturn();
    }

    private String postTaskId() throws Exception {
        return idOf(postTask("Test task", "Test description"));
    }

    private String idOf(MvcResult result) throws Exception {
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.get("id").asText();
    }

    @Test
    void indexReturns200() throws Exception {
        mockMvc.perform(get("/")).andExpect(status().isOk());
    }

    @Test
    void healthReturns200() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("ok")));
    }

    @Test
    void getTasksEmpty() throws Exception {
        mockMvc.perform(get("/tasks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void createTask() throws Exception {
        mockMvc.perform(post("/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\": \"Buy milk\", \"description\": \"2%\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.title", is("Buy milk")))
                .andExpect(jsonPath("$.description", is("2%")))
                .andExpect(jsonPath("$.completed", is(false)))
                .andExpect(jsonPath("$.id").exists());
    }

    @Test
    void createTaskMissingTitle() throws Exception {
        mockMvc.perform(post("/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"description\": \"no title\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createTaskMissingBody() throws Exception {
        mockMvc.perform(post("/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(""))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createTaskDefaultsDescription() throws Exception {
        mockMvc.perform(post("/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\": \"No description\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.description", is("")));
    }

    @Test
    void getTasksAfterCreate() throws Exception {
        postTask("Test task", "Test description");
        mockMvc.perform(get("/tasks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }

    @Test
    void getTaskById() throws Exception {
        String taskId = postTaskId();
        mockMvc.perform(get("/tasks/" + taskId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(taskId)));
    }

    @Test
    void getTaskNotFound() throws Exception {
        mockMvc.perform(get("/tasks/does-not-exist")).andExpect(status().isNotFound());
    }

    @Test
    void updateTask() throws Exception {
        String taskId = postTaskId();
        mockMvc.perform(put("/tasks/" + taskId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\": \"Updated\", \"completed\": true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title", is("Updated")))
                .andExpect(jsonPath("$.completed", is(true)));
    }

    @Test
    void updateTaskPartial() throws Exception {
        String taskId = idOf(postTask("Original", "Original desc"));
        mockMvc.perform(put("/tasks/" + taskId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"completed\": true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title", is("Original")))
                .andExpect(jsonPath("$.description", is("Original desc")))
                .andExpect(jsonPath("$.completed", is(true)));
    }

    @Test
    void updateTaskNotFound() throws Exception {
        mockMvc.perform(put("/tasks/does-not-exist")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\": \"x\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteTask() throws Exception {
        String taskId = postTaskId();
        mockMvc.perform(delete("/tasks/" + taskId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result", is(true)));
        mockMvc.perform(get("/tasks/" + taskId)).andExpect(status().isNotFound());
    }

    @Test
    void deleteTaskNotFound() throws Exception {
        mockMvc.perform(delete("/tasks/does-not-exist")).andExpect(status().isNotFound());
    }
}
