package com.usage.claudewidget.widget

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.LocalContext
import android.content.Intent
import com.usage.claudewidget.R
import com.usage.claudewidget.ui.MainActivity

/** Immutable view state handed to the composable; assembled from Storage on each render. */
data class WidgetState(
    val needsLogin: Boolean,
    val hasData: Boolean,
    val fiveHourPct: Int,
    val fiveHourResets: String,
    val sevenDayPct: Int,
    val sevenDayResets: String,
    val stale: Boolean,
)

private val COMPACT_MAX_WIDTH = 130.dp

// Colors come from resources so they auto-adapt to light/dark via values-night.
private val accent = ColorProvider(R.color.accent)
private fun barTrack() = ColorProvider(R.color.bar_track)

@Composable
fun UsageWidgetContent(state: WidgetState) {
    val size = LocalSize.current
    val compact = size.width < COMPACT_MAX_WIDTH
    val context = LocalContext.current

    val tap = if (state.needsLogin) {
        actionStartActivity(Intent(context, MainActivity::class.java))
    } else {
        actionRunCallback<RefreshAction>()
    }

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(GlanceTheme.colors.widgetBackground)
            .cornerRadius(20.dp)
            .padding(if (compact) 8.dp else 12.dp)
            .clickable(tap),
    ) {
        when {
            state.needsLogin -> SignInPrompt(compact)
            !state.hasData -> Loading(compact)
            compact -> CompactLayout(state)
            else -> FullLayout(state)
        }
        if (state.hasData && state.stale) StaleDot()
    }
}

@Composable
private fun FullLayout(s: WidgetState) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Lobster(22.dp)
            Spacer(GlanceModifier.width(6.dp))
            Text(
                "Claude usage",
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontWeight = FontWeight.Medium,
                ),
            )
        }
        Spacer(GlanceModifier.height(10.dp))
        MeterRow("5H", s.fiveHourPct, s.fiveHourResets)
        Spacer(GlanceModifier.height(10.dp))
        MeterRow("1W", s.sevenDayPct, s.sevenDayResets)
    }
}

@Composable
private fun MeterRow(label: String, pct: Int, resets: String) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                label,
                style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontWeight = FontWeight.Bold),
                modifier = GlanceModifier.width(28.dp),
            )
            Text(
                "$pct%",
                style = TextStyle(color = GlanceTheme.colors.onSurface, fontWeight = FontWeight.Bold),
            )
            Spacer(GlanceModifier.defaultWeight())
            Text(
                "resets in $resets",
                style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant),
            )
        }
        Spacer(GlanceModifier.height(4.dp))
        Bar(pct)
    }
}

@Composable
private fun CompactLayout(s: WidgetState) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Lobster(16.dp)
        Spacer(GlanceModifier.height(6.dp))
        CompactMeter("5H", s.fiveHourPct)
        Spacer(GlanceModifier.height(6.dp))
        CompactMeter("1W", s.sevenDayPct)
    }
}

@Composable
private fun CompactMeter(label: String, pct: Int) {
    Column(modifier = GlanceModifier.fillMaxWidth()) {
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            Text(
                label,
                style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontWeight = FontWeight.Bold),
            )
            Spacer(GlanceModifier.defaultWeight())
            Text(
                "$pct%",
                style = TextStyle(color = GlanceTheme.colors.onSurface, fontWeight = FontWeight.Bold),
            )
        }
        Spacer(GlanceModifier.height(3.dp))
        Bar(pct)
    }
}

@Composable
private fun Bar(pct: Int) {
    LinearProgressIndicator(
        progress = (pct.coerceIn(0, 100)) / 100f,
        modifier = GlanceModifier.fillMaxWidth().height(6.dp).cornerRadius(3.dp),
        color = accent,
        backgroundColor = barTrack(),
    )
}

@Composable
private fun Lobster(s: androidx.compose.ui.unit.Dp) {
    Image(
        provider = ImageProvider(R.drawable.ic_lobster),
        contentDescription = "Claude",
        modifier = GlanceModifier.size(s),
    )
}

@Composable
private fun SignInPrompt(compact: Boolean) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Lobster(if (compact) 18.dp else 24.dp)
        Spacer(GlanceModifier.height(6.dp))
        Text(
            if (compact) "Sign in" else "Tap to sign in",
            style = TextStyle(color = GlanceTheme.colors.onSurface, fontWeight = FontWeight.Medium),
        )
    }
}

@Composable
private fun Loading(compact: Boolean) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("…", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant))
    }
}

@Composable
private fun StaleDot() {
    Box(
        modifier = GlanceModifier.fillMaxSize().padding(2.dp),
        contentAlignment = Alignment.TopEnd,
    ) {
        Box(
            modifier = GlanceModifier
                .size(8.dp)
                .cornerRadius(4.dp)
                .background(ColorProvider(R.color.stale)),
        ) {}
    }
}
