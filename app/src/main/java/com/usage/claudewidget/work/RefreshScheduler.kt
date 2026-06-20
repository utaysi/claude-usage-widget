package com.usage.claudewidget.work

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.usage.claudewidget.data.Const
import java.util.concurrent.TimeUnit

object RefreshScheduler {

    private val networkConstraint =
        Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

    /** Periodic 15-minute refresh; survives reboot. Idempotent (KEEP). */
    fun ensurePeriodic(context: Context) {
        val work = PeriodicWorkRequestBuilder<RefreshWorker>(
            Const.REFRESH_INTERVAL_MIN, TimeUnit.MINUTES
        )
            .setConstraints(networkConstraint)
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            Const.WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, work
        )
    }

    /** Manual tap-to-refresh: run once now, ahead of the periodic schedule. */
    fun refreshNow(context: Context) {
        val work = OneTimeWorkRequestBuilder<RefreshWorker>()
            .setConstraints(networkConstraint)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            "${Const.WORK_NAME}-now", ExistingWorkPolicy.REPLACE, work
        )
    }
}
