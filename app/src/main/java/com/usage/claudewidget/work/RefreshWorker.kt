package com.usage.claudewidget.work

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.usage.claudewidget.data.FetchResult
import com.usage.claudewidget.data.UsageRepository
import com.usage.claudewidget.widget.UsageWidget

/** Fetches usage in the background and pushes the result into the widget. */
class RefreshWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val result = UsageRepository(applicationContext).refresh()
        // Snapshot + authState are already persisted by the repository; just re-render.
        UsageWidget.updateAll(applicationContext)
        return when (result) {
            is FetchResult.Success, is FetchResult.NeedsLogin -> Result.success()
            is FetchResult.Soft -> Result.retry() // transient; let WorkManager back off
        }
    }
}
