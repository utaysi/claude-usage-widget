package com.usage.claudewidget.data

import android.webkit.CookieManager

/** Reads claude.ai cookies out of the WebView cookie jar into [Storage]. */
object CookieHarvester {
    fun harvest(storage: Storage): Boolean {
        val cm = CookieManager.getInstance()
        val raw = cm.getCookie(Const.BASE) ?: return false
        val map = raw.split(';')
            .mapNotNull { part ->
                val i = part.indexOf('=')
                if (i <= 0) null else part.substring(0, i).trim() to part.substring(i + 1).trim()
            }.toMap()

        val session = map[Const.COOKIE_SESSION]
        val cf = map[Const.COOKIE_CF]
        var changed = false
        if (!session.isNullOrBlank()) { storage.sessionKey = session; changed = true }
        if (!cf.isNullOrBlank()) { storage.cfClearance = cf; changed = true }
        // Best-effort org id fallback straight from the cookie.
        map[Const.COOKIE_LAST_ORG]?.let { if (storage.orgId.isNullOrBlank()) storage.orgId = it }
        return changed
    }
}
