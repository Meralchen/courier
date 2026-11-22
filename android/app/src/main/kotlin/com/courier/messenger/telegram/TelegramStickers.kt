package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import java.util.Collections
import java.util.concurrent.atomic.AtomicInteger
import org.drinkless.tdlib.TdApi

/**
 * Sticker panel data. TDLib's recent stickers answer immediately; installed
 * sets give ids, so the first few are expanded with `GetStickerSet` for the
 * panel's grid. Thumbnails are requested up front and arrive through the normal
 * `file` updates.
 */
internal fun TelegramEngine.requestStickers(result: MethodChannel.Result) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    c.send(TdApi.GetRecentStickers(false)) { recentReply ->
        val recent = (recentReply as? TdApi.Stickers)?.stickers ?: emptyArray()
        c.send(TdApi.GetInstalledStickerSets(TdApi.StickerTypeRegular())) { setsReply ->
            val sets = (setsReply as? TdApi.StickerSets)?.sets?.take(3) ?: emptyList()
            if (sets.isEmpty()) {
                val payload = mapOf(
                    "recent" to recent.map { stickerMap(it) },
                    "sets" to emptyList<Map<String, Any?>>(),
                )
                main.post {
                    emit(mapOf("type" to "stickers", "stickers" to payload))
                    result.success(payload)
                }
            } else {
                val pending = AtomicInteger(sets.size)
                val packs = Collections.synchronizedList(ArrayList<Map<String, Any?>>())
                for (info in sets) {
                    c.send(TdApi.GetStickerSet(info.id)) { setReply ->
                        if (setReply is TdApi.StickerSet) {
                            packs.add(
                                mapOf(
                                    "id" to setReply.id,
                                    "title" to setReply.title,
                                    "stickers" to setReply.stickers.take(40).map { stickerMap(it) },
                                ),
                            )
                        }
                        if (pending.decrementAndGet() == 0) {
                            val payload = mapOf(
                                "recent" to recent.map { stickerMap(it) },
                                "sets" to packs.toList(),
                            )
                            main.post {
                                emit(mapOf("type" to "stickers", "stickers" to payload))
                                result.success(payload)
                            }
                        }
                    }
                }
            }
        }
    }
}

/** Sends a sticker by the file id TDLib already knows for it. */
internal fun TelegramEngine.sendSticker(
    chatId: Long,
    fileId: Int,
    emoji: String,
    width: Int,
    height: Int,
    result: MethodChannel.Result,
) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    val sticker = TdApi.InputSticker(
        TdApi.InputFileId(fileId),
        null,
        width.coerceAtLeast(1),
        height.coerceAtLeast(1),
    )
    val content = TdApi.InputMessageSticker(sticker, emoji)
    c.send(TdApi.SendMessage(chatId, null, null, null, null, content)) { reply ->
        main.post {
            when (reply) {
                is TdApi.Message -> {
                    addMessage(reply)
                    result.success(null)
                }
                is TdApi.Error -> {
                    emitError(reply.message)
                    result.error("tdlib", reply.message, null)
                }
                else -> result.success(null)
            }
        }
    }
}

private fun TelegramEngine.stickerMap(sticker: TdApi.Sticker): Map<String, Any?> {
    val thumb = sticker.thumbnail?.file
    ensureDownload(thumb)
    return mapOf(
        "fileId" to sticker.sticker.id,
        "thumbnailFileId" to (thumb?.id ?: 0),
        "thumbnailPath" to TdFormat.localPath(thumb),
        "width" to sticker.width,
        "height" to sticker.height,
        "emoji" to sticker.emoji,
        "animated" to (sticker.format is TdApi.StickerFormatTgs ||
            sticker.format is TdApi.StickerFormatWebm),
    )
}
