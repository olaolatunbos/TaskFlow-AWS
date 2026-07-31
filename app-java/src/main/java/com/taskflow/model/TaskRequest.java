package com.taskflow.model;

/**
 * Incoming task payload. Fields are boxed so an absent key is distinguishable
 * from a supplied one, which is what makes PUT a partial update.
 */
public record TaskRequest(String title, String description, Boolean completed) {}
