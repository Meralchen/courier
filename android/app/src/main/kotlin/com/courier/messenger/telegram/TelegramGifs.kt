package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi

/**
 * Saved animations for the sticker keyboard's GIF tab. TDLib stores them per
 * account and returns full `Animation` objects, so no extra lookup is needed.
 */
internal fun TelegramEngine.requestSavedGifs(result: MethodChannel.Result) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    c.send(TdApi.GetSavedAnimations()) { reply ->
        main.post {
            if (reply is TdApi.Animations) {
                val rows = reply.animations.map { animation ->
                    val thumb = animation.thumbnail?.file
                    ensureDownload(thumb)
                    val size = animation.animation.size.coerceAtMost(Int.MAX_VALUE.toLong())
                    mapOf(
                        "fileId" to animation.animation.id,
                        "thumbnailFileId" to (thumb?.id ?: 0),
                        "thumbnailPath" to TdFormat.localPath(thumb),
                        "width" to animation.width,
                        "height" to animation.height,
                        "duration" to animation.duration,
                        "fileName" to animation.fileName,
                        "fileSize" to size.toInt(),
                    )
                }
                result.success(rows)
            } else {
                if (reply is TdApi.Error) emitError(reply.message)
                result.success(emptyList<Map<String, Any?>>())
            }
        }
    }
}

/** Sends a saved GIF as `InputMessageAnimation`, the only GIF send path. */
internal fun TelegramEngine.sendGif(
    chatId: Long,
    fileId: Int,
    width: Int,
    height: Int,
    duration: Int,
    result: MethodChannel.Result,
) {
    val animation = TdApi.InputAnimation(
        TdApi.InputFileId(fileId),
        null,
        intArrayOf(),
        duration,
        width,
        height,
    )
    val content = TdApi.InputMessageAnimation(
        animation,
        TdApi.FormattedText("", emptyArray()),
        false,
        false,
    )
    client?.send(TdApi.SendMessage(chatId, null, null, null, null, content)) { reply ->
        main.post {
            if (reply is TdApi.Message) {
                result.success(null)
            } else if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}
