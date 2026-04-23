package com.example.hello;

import java.time.Instant;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @Value("${app.message:Hello from Spring Boot on Kubernetes via Argo CD}")
    private String message;

    @GetMapping("/")
    public Map<String, Object> home() {
        return Map.of(
            "message", message,
            "timestamp", Instant.now().toString()
        );
    }

    @GetMapping("/hello")
    public Map<String, String> hello() {
        return Map.of("greeting", "Hello World");
    }
}
