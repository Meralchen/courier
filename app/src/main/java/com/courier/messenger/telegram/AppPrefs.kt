package com.courier.messenger.telegram

import android.content.Context

data class ApiCredentials(val apiId: Int, val apiHash: String)

object AppPrefs {
    private const val FILE = "courier_prefs"
    private const val KEY_ID = "api_id"
    private const val KEY_HASH = "api_hash"

    /**
     * Stored keys win; otherwise the caller's build-time application keys apply.
     * Credentials live in the app module because AGP only exposes BuildConfig
     * there, so they are injected instead of imported.
     */
    fun load(context: Context, builtInApiId: Int?, builtInApiHash: String): ApiCredentials? {
        val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        val storedId = prefs.getString(KEY_ID, null)
        val storedHash = prefs.getString(KEY_HASH, null)
        if (storedId != null && storedHash != null) {
            storedId.toIntOrNull()?.let { return ApiCredentials(it, storedHash) }
        }
        return if (builtInApiId != null && builtInApiId > 0 && builtInApiHash.isNotBlank()) {
            ApiCredentials(builtInApiId, builtInApiHash)
        } else {
            null
        }
    }

    fun save(context: Context, apiId: Int, apiHash: String) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ID, apiId.toString())
            .putString(KEY_HASH, apiHash)
            .apply()
    }

    fun clear(context: Context) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit().clear().apply()
    }
}
