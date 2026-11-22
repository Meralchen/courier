package com.courier.messenger

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.courier.messenger.telegram.CourierTelegramPlugin

/**
 * Single Flutter activity. The Telegram engine lives in a Flutter plugin so it
 * survives configuration changes and keeps one TDLib client per process. Voice
 * recording is a second, tiny channel because it needs this activity for the
 * microphone permission dialog.
 */
class MainActivity : FlutterActivity() {
    private var recorder: VoiceRecorder? = null
    private var pendingStart: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(CourierTelegramPlugin())

        val voice = VoiceRecorder(this)
        recorder = voice
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
                else -> result.notImplemented()
            }
        }
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

    companion object {
        const val VOICE_CHANNEL = "courier/voice"
    }
}
