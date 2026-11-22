package com.courier.messenger

import android.media.MediaPlayer

/**
 * Plays downloaded voice notes and audio messages. A single player is enough:
 * starting a new recording stops the previous one, which is also what iOS does.
 */
internal class VoicePlayer {
    private var player: MediaPlayer? = null

    @Synchronized
    fun play(path: String): Boolean {
        stop()
        return try {
            val media = MediaPlayer()
            media.setDataSource(path)
            media.prepare()
            media.start()
            media.setOnCompletionListener { stop() }
            player = media
            true
        } catch (t: Throwable) {
            stop()
            false
        }
    }

    @Synchronized
    fun stop() {
        val media = player ?: return
        player = null
        runCatching { if (media.isPlaying) media.stop() }
        runCatching { media.release() }
    }

    @Synchronized
    fun isPlaying(): Boolean = player?.isPlaying == true
}
