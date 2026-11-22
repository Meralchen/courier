package com.courier.messenger

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.os.SystemClock
import java.io.File

/**
 * Voice notes recorded with the platform encoder and sent through TDLib.
 *
 * MediaRecorder is enough here: Telegram voice notes are AAC in an MPEG-4
 * container, which is exactly what the platform writes. Keeping this in the
 * activity avoids a plugin dependency for one button.
 */
internal class VoiceRecorder(private val activity: Activity) {
    private var recorder: MediaRecorder? = null
    private var file: File? = null
    private var startedAt = 0L

    fun hasPermission(): Boolean =
        activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    fun requestPermission() {
        activity.requestPermissions(
            arrayOf(Manifest.permission.RECORD_AUDIO),
            REQUEST_CODE,
        )
    }

    /** Starts recording and returns the output path. */
    @Synchronized
    fun start(): String {
        cancel()
        val dir = File(activity.cacheDir, "voice").apply { mkdirs() }
        val output = File(dir, "note-${System.currentTimeMillis()}.m4a")
        val media = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(activity)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        media.setAudioSource(MediaRecorder.AudioSource.MIC)
        media.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        media.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        media.setAudioChannels(1)
        media.setAudioSamplingRate(48000)
        media.setAudioEncodingBitRate(96000)
        media.setOutputFile(output.absolutePath)
        media.prepare()
        media.start()
        recorder = media
        file = output
        startedAt = SystemClock.elapsedRealtime()
        return output.absolutePath
    }

    /** Stops recording and returns `{path, duration, size}`. */
    @Synchronized
    fun stop(): Map<String, Any?>? {
        val media = recorder ?: return null
        recorder = null
        val output = file
        file = null
        val seconds = ((SystemClock.elapsedRealtime() - startedAt) / 1000L)
            .coerceAtLeast(1L)
            .coerceAtMost(Int.MAX_VALUE.toLong())
        val path = try {
            media.stop()
            output?.absolutePath
        } catch (t: Throwable) {
            null
        } finally {
            media.release()
        }
        if (path == null) return null
        return mapOf(
            "path" to path,
            "duration" to seconds.toInt(),
            "size" to (output?.length() ?: 0L),
        )
    }

    @Synchronized
    fun cancel() {
        val media = recorder ?: return
        recorder = null
        try {
            media.stop()
        } catch (_: Throwable) {
        }
        media.release()
        file?.delete()
        file = null
    }

    companion object {
        const val REQUEST_CODE = 7401
    }
}
