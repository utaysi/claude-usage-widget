package com.usage.claudewidget.auth

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import com.usage.claudewidget.data.Const
import com.usage.claudewidget.data.CookieHarvester
import com.usage.claudewidget.data.Storage
import com.usage.claudewidget.widget.UsageWidget
import com.usage.claudewidget.work.RefreshScheduler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * One-time interactive login. Loads claude.ai in a WebView; once a sessionKey cookie
 * appears, harvests cookies + the WebView's User-Agent, then finishes.
 */
class LoginActivity : Activity() {

    private lateinit var webView: WebView
    private val storage by lazy { Storage.get(this) }
    private var captured = false

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val cm = CookieManager.getInstance()
        cm.setAcceptCookie(true)

        webView = WebView(this).apply {
            cm.setAcceptThirdPartyCookies(this, true)
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            // Persist the exact UA so cf_clearance stays valid for headless fetches.
            storage.userAgent = settings.userAgentString

            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView, url: String) {
                    tryCapture()
                }
            }
            loadUrl(Const.LOGIN_URL)
        }
        setContentView(webView)
    }

    private fun tryCapture() {
        if (captured) return
        val cookies = CookieManager.getInstance().getCookie(Const.BASE) ?: return
        if (!cookies.contains("${Const.COOKIE_SESSION}=")) return

        captured = true
        CookieManager.getInstance().flush()
        CookieHarvester.harvest(storage)

        // Discover org + first snapshot, then schedule periodic refresh.
        CoroutineScope(Dispatchers.Main).launch {
            RefreshScheduler.ensurePeriodic(this@LoginActivity)
            RefreshScheduler.refreshNow(this@LoginActivity)
            UsageWidget.updateAll(this@LoginActivity)
            Toast.makeText(this@LoginActivity, "Signed in", Toast.LENGTH_SHORT).show()
            setResult(Activity.RESULT_OK)
            finish()
        }
    }

    override fun onDestroy() {
        if (::webView.isInitialized) webView.destroy()
        super.onDestroy()
    }
}
