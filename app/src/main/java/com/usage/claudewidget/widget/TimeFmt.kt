package com.usage.claudewidget.widget

object TimeFmt {
    /** "resets in" value, e.g. "3h 12m", "5d 2h", "<1m", or "-" if unknown. */
    fun resetsIn(resetEpochMs: Long, now: Long = System.currentTimeMillis()): String {
        if (resetEpochMs <= 0L) return "-"
        var s = (resetEpochMs - now) / 1000
        if (s <= 0) return "now"
        val d = s / 86_400; s %= 86_400
        val h = s / 3_600; s %= 3_600
        val m = s / 60
        return when {
            d > 0 -> "${d}d ${h}h"
            h > 0 -> "${h}h ${m}m"
            m > 0 -> "${m}m"
            else -> "<1m"
        }
    }

    /** Snapshot is considered stale once older than ~2 refresh cycles. */
    fun isStale(fetchedAt: Long, now: Long = System.currentTimeMillis()): Boolean {
        if (fetchedAt <= 0L) return true
        return now - fetchedAt > 31 * 60 * 1000L // > 31 min
    }
}
