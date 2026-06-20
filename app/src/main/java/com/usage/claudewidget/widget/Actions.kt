package com.usage.claudewidget.widget

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import com.usage.claudewidget.work.RefreshScheduler

/** Tap action when the widget is healthy: kick off an immediate refresh. */
class RefreshAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        RefreshScheduler.refreshNow(context)
    }
}
