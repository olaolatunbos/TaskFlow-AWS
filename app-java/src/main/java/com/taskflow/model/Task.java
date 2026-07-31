package com.taskflow.model;

/** A task, serialised as {"id", "title", "description", "completed"}. */
public record Task(String id, String title, String description, boolean completed) {}
