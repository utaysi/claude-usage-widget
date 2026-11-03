package com.usage.claudewidget.data

import org.junit.Assert.*
import org.junit.Test

class UsageSnapshotTest {
    @Test fun maxPlanNullFiveHour() {
        val s = UsageSnapshot.parse("""{"five_hour":null,"seven_day":{"utilization":42.0,"resets_at":"2026-11-07T20:00:00.48+00:00"}}""", 1L)
        assertNull(s.fiveHour)
        assertEquals(42f, s.sevenDay.utilization)
        assertTrue(s.sevenDay.resetsAtEpochMs > 0)
    }
    @Test fun missingFiveHour() {
        assertNull(UsageSnapshot.parse("""{"seven_day":{"utilization":1}}""", 1L).fiveHour)
    }
    @Test fun proPlanStillParsesFiveHour() {
        val s = UsageSnapshot.parse("""{"five_hour":{"utilization":12.5,"resets_at":"2026-11-03T20:00:00+00:00"},"seven_day":{"utilization":3}}""", 1L)
        assertEquals(12.5f, s.fiveHour!!.utilization)
    }
}
