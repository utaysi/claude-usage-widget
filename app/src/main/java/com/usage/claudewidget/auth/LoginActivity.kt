package com.usage.claudewidget.auth

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
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
 *
 * "Continue with Google" opens a popup and hands the credential back via window.opener,
 * so popups are hosted in child WebViews stacked over the main one.
 */
class LoginActivity : Activity() {

    private lateinit var container: FrameLayout
    private lateinit var webView: WebView
    private val popups = mutableListOf<WebView>()
    private val storage by lazy { Storage.get(this) }
    private var captured = false

    // SPA logins set the cookie via fetch without a page load, so poll as a fallback.
    private val handler = Handler(Looper.getMainLooper())
    private val poll = object : Runnable {
        override fun run() {
            tryCapture()
            if (!captured) handler.postDelayed(this, POLL_MS)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        CookieManager.getInstance().setAcceptCookie(true)

        container = FrameLayout(this)
        webView = newWebView().apply {
            // Persist the exact UA so cf_clearance stays valid for headless fetches.
            storage.userAgent = settings.userAgentString
            loadUrl(Const.LOGIN_URL)
        }
        container.addView(webView)
        setContentView(container)
        handler.postDelayed(poll, POLL_MS)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun newWebView(): WebView = WebView(this).apply {
        CookieManager.getInstance().setAcceptThirdPartyCookies(this, true)
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.javaScriptCanOpenWindowsAutomatically = true
        settings.setSupportMultipleWindows(true)

        webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String) {
                tryCapture()
            }

            override fun doUpdateVisitedHistory(view: WebView, url: String, isReload: Boolean) {
                tryCapture()
            }
        }

        webChromeClient = object : WebChromeClient() {
            override fun onCreateWindow(
                view: WebView, isDialog: Boolean, isUserGesture: Boolean, resultMsg: Message,
            ): Boolean {
                val popup = newWebView()
                popups.add(popup)
                container.addView(popup)
                (resultMsg.obj as WebView.WebViewTransport).webView = popup
                resultMsg.sendToTarget()
                return true
            }

            override fun onCloseWindow(window: WebView) {
                if (popups.remove(window)) {
                    container.removeView(window)
                    window.destroy()
                }
                tryCapture()
            }
        }
    }

    private fun tryCapture() {
        if (captured) return
        val cookies = CookieManager.getInstance().getCookie(Const.BASE) ?: return
        if (!cookies.contains("${Const.COOKIE_SESSION}=")) return

        captured = true
        handler.removeCallbacks(poll)
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
        handler.removeCallbacks(poll)
        popups.forEach { it.destroy() }
        popups.clear()
        if (::webView.isInitialized) webView.destroy()
        super.onDestroy()
    }

    private companion object {
        const val POLL_MS = 1000L
    }
}
