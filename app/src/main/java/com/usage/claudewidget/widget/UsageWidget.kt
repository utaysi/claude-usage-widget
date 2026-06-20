package com.usage.claudewidget.widget

import android.content.Context
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.updateAll
import com.usage.claudewidget.data.AuthState
import com.usage.claudewidget.data.Storage
import kotlin.math.roundToInt

class UsageWidget : GlanceAppWidget() {

    // Two reusable buckets; Glance maps any real size to the nearest one.
    override val sizeMode = SizeMode.Responsive(
        setOf(
            DpSize(60.dp, 60.dp),    // Compact (~1x1)
            DpSize(180.dp, 110.dp),  // Full
        )
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                UsageWidgetContent(readState(context))
            }
        }
    }

    private fun readState(context: Context): WidgetState {
        val s = Storage.get(context)
        val now = System.currentTimeMillis()
        return WidgetState(
            needsLogin = !s.isLoggedIn || s.authState == AuthState.NEEDS_LOGIN,
            hasData = s.hasSnapshot,
            fiveHourPct = s.fiveHourUtil.coerceAtLeast(0f).roundToInt(),
            fiveHourResets = TimeFmt.resetsIn(s.fiveHourReset, now),
            sevenDayPct = s.sevenDayUtil.coerceAtLeast(0f).roundToInt(),
            sevenDayResets = TimeFmt.resetsIn(s.sevenDayReset, now),
            stale = TimeFmt.isStale(s.fetchedAt, now),
        )
    }

    companion object {
        suspend fun updateAll(context: Context) = UsageWidget().updateAll(context)
    }
}
