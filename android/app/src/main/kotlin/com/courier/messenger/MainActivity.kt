package com.courier.messenger

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.courier.messenger.telegram.CourierNotifications
import com.courier.messenger.telegram.CourierTelegramPlugin
import java.io.File
import java.io.FileOutputStream

/**
 * Single Flutter activity. The Telegram engine lives in a Flutter plugin so it
 * survives configuration changes and keeps one TDLib client per process. Voice
 * recording is a second, tiny channel because it needs this activity for the
 * microphone permission dialog.
 */
class MainActivity : FlutterActivity() {
    private var recorder: VoiceRecorder? = null
    private var player: VoicePlayer? = null
    private var pendingStart: MethodChannel.Result? = null
    private var pendingFile: MethodChannel.Result? = null
    private var pendingChatId: Long = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingChatId = intent?.getLongExtra(CourierNotifications.EXTRA_CHAT_ID, 0L) ?: 0L
        // Notifications are the only permission the shell needs up front; the
        // Telegram engine silently skips them until Android grants it.
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATIONS_REQUEST,
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(CourierTelegramPlugin())

        val voice = VoiceRecorder(this)
        recorder = voice
        val playback = VoicePlayer()
        player = playback
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VOICE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> startVoice(voice, result)
                "stop" -> {
                    val clip = try {
                        voice.stop()
                    } catch (t: Throwable) {
                        result.error("voice", t.message ?: "Recording failed", null)
                        return@setMethodCallHandler
                    }
                    if (clip == null) {
                        result.error("voice", "Nothing is being recorded", null)
                    } else {
                        result.success(clip)
                    }
                }
                "cancel" -> {
                    voice.cancel()
                    result.success(null)
                }
                "play" -> {
                    voice.cancel()
                    val path = call.argument<String>("path") ?: ""
                    if (path.isNotEmpty() && playback.play(path)) {
                        result.success(null)
                    } else {
                        result.error("voice", "Could not play the recording", null)
                    }
                }
                "stopPlayback" -> {
                    playback.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATIONS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pendingChat" -> {
                    val chatId = pendingChatId
                    pendingChatId = 0L
                    result.success(chatId)
                }
                else -> result.notImplemented()
            }
        }

        // Documents come from Android's own file picker so the app does not
        // carry a picker plugin; the chosen file is copied into our cache so
        // TDLib can read a stable local path.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pick" -> pickFile(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickFile(result: MethodChannel.Result) {
        if (pendingFile != null) {
            result.error("file", "Another file picker is already open", null)
            return
        }
        pendingFile = result
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
            }
            startActivityForResult(intent, FILE_REQUEST)
        } catch (t: Throwable) {
            pendingFile = null
            result.error("file", "No file picker is available", null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingChatId = intent.getLongExtra(CourierNotifications.EXTRA_CHAT_ID, 0L)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != FILE_REQUEST) return
        val pending = pendingFile ?: return
        pendingFile = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.success(null)
            return
        }
        try {
            val name = (displayName(uri) ?: "file").replace('/', '_')
            // One directory per pick keeps the original file name, which is
            // what TDLib shows as the document name in the conversation.
            val dir = File(File(cacheDir, "attachments"), "${System.currentTimeMillis()}")
                .apply { mkdirs() }
            val target = File(dir, name)
            contentResolver.openInputStream(uri).use { input ->
                if (input == null) {
                    throw IllegalStateException("Could not read the file")
                }
                FileOutputStream(target).use { output -> input.copyTo(output) }
            }
            pending.success(
                mapOf(
                    "path" to target.absolutePath,
                    "name" to name,
                    "size" to target.length(),
                ),
            )
        } catch (t: Throwable) {
            pending.error("file", t.message ?: "Could not read the file", null)
        }
    }

    private fun displayName(uri: Uri): String? =
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }

    private fun startVoice(voice: VoiceRecorder, result: MethodChannel.Result) {
        if (voice.hasPermission()) {
            try {
                result.success(voice.start())
            } catch (t: Throwable) {
                result.error("voice", t.message ?: "Recording failed", null)
            }
            return
        }
        pendingStart = result
        voice.requestPermission()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != VoiceRecorder.REQUEST_CODE) return
        val result = pendingStart
        pendingStart = null
        val voice = recorder
        if (result == null) return
        val granted = grantResults.firstOrNull() ==
            android.content.pm.PackageManager.PERMISSION_GRANTED
        if (!granted || voice == null) {
            result.error(
                "permission",
                "Microphone access is needed to record a voice message",
                null,
            )
            return
        }
        try {
            result.success(voice.start())
        } catch (t: Throwable) {
            result.error("voice", t.message ?: "Recording failed", null)
        }
    }

    override fun onDestroy() {
        player?.stop()
        recorder?.cancel()
        super.onDestroy()
    }

    companion object {
        const val VOICE_CHANNEL = "courier/voice"
        const val FILE_CHANNEL = "courier/files"
        const val NOTIFICATIONS_CHANNEL = "courier/notifications"
        private const val NOTIFICATIONS_REQUEST = 7402
        private const val FILE_REQUEST = 7403
    }
}
