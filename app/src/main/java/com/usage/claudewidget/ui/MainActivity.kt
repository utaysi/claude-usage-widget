package com.usage.claudewidget.ui

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.usage.claudewidget.auth.LoginActivity
import com.usage.claudewidget.data.FetchResult
import com.usage.claudewidget.data.Storage
import com.usage.claudewidget.data.UsageRepository
import com.usage.claudewidget.widget.UsageWidget
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    SetupScreen()
                }
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun SetupScreen() {
    val context = LocalContext.current
    val storage = remember { Storage.get(context) }
    val scope = rememberCoroutineScope()

    var status by remember { mutableStateOf(describe(storage)) }
    var debug by remember { mutableStateOf("") }

    val loginLauncher = androidx.activity.compose.rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        status = describe(storage)
    }

    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("Claude Usage Widget", style = MaterialTheme.typography.headlineSmall)
        Text(status, style = MaterialTheme.typography.bodyMedium)

        Button(onClick = { loginLauncher.launch(Intent(context, LoginActivity::class.java)) }) {
            Text(if (storage.isLoggedIn) "Re-sign in" else "Sign in")
        }

        OutlinedButton(onClick = {
            scope.launch {
                debug = "Fetching…"
                debug = when (val r = UsageRepository(context).refresh()) {
                    is FetchResult.Success -> {
                        UsageWidget.updateAll(context)
                        "5H: ${r.snapshot.fiveHour.utilization}%   " +
                            "1W: ${r.snapshot.sevenDay.utilization}%"
                    }
                    is FetchResult.NeedsLogin -> "Session expired. Sign in again."
                    is FetchResult.Soft -> "Transient: ${r.reason}"
                }
                status = describe(storage)
            }
        }) { Text("Test fetch now") }

        OutlinedButton(onClick = { requestBatteryExemption(context) }) {
            Text("Disable battery optimization")
        }

        if (debug.isNotBlank()) {
            Text(debug, style = MaterialTheme.typography.titleMedium)
        }
    }
}

private fun describe(s: Storage): String = buildString {
    append(if (s.isLoggedIn) "Signed in ✓" else "Not signed in")
    append("\norg: ").append(s.orgId ?: "-")
    if (s.hasSnapshot) {
        append("\nlast: 5H ").append(s.fiveHourUtil.toInt()).append("%  1W ")
            .append(s.sevenDayUtil.toInt()).append("%")
    }
}

private fun requestBatteryExemption(context: Context) {
    val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
    if (!pm.isIgnoringBatteryOptimizations(context.packageName)) {
        val intent = Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:${context.packageName}")
        )
        context.startActivity(intent)
    }
}
