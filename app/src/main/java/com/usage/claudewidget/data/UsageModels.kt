package com.usage.claudewidget.data

import org.json.JSONObject

/** One usage window (5-hour or 7-day). */
data class Window(
    val utilization: Float,      // percent, 0..100
    val resetsAtEpochMs: Long,   // absolute reset time
)

/** Parsed snapshot of the /usage endpoint. */
data class UsageSnapshot(
    val fiveHour: Window?,       // null on plans without a 5-hour limit (API sends `"five_hour": null`)
    val sevenDay: Window,
    val fetchedAtEpochMs: Long,
) {
    companion object {
        fun parse(body: String, now: Long): UsageSnapshot {
            val root = JSONObject(body)
            return UsageSnapshot(
                fiveHour = root.optJSONObject("five_hour")?.toWindow(),
                sevenDay = root.getJSONObject("seven_day").toWindow(),
                fetchedAtEpochMs = now,
            )
        }

        private fun JSONObject.toWindow(): Window {
            val util = optDouble("utilization", 0.0).toFloat()
            val reset = optString("resets_at", "")
            return Window(util, Iso8601.toEpochMs(reset))
        }
    }
}
