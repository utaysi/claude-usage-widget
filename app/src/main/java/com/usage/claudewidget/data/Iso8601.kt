package com.usage.claudewidget.data

import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter

/** Parses the API's RFC3339 timestamps, e.g. "2026-06-20T20:00:00.483321+00:00". */
object Iso8601 {
    fun toEpochMs(value: String): Long {
        if (value.isBlank()) return 0L
        return try {
            OffsetDateTime.parse(value, DateTimeFormatter.ISO_OFFSET_DATE_TIME)
                .toInstant().toEpochMilli()
        } catch (_: Exception) {
            0L
        }
    }
}
