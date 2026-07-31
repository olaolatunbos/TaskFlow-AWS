package com.taskflow.web;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Plain {@code /health} endpoint rather than Actuator's {@code /actuator/health}:
 * the ALB target group health check path is {@code /health}.
 */
@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "ok");
    }
}
