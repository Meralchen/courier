package com.courier.messenger.telegram

import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi
import java.io.File

/** Video attachments keep their real dimensions and duration in the bubble. */
internal fun TelegramEngine.sendVideo(
    chatId: Long,
    path: String,
    caption: String,
    replyToId: Long,
    result: MethodChannel.Result,
) {
    var width = 0
    var height = 0
    var duration = 0
    val retriever = MediaMetadataRetriever()
    try {
        retriever.setDataSource(path)
        width = retriever
            .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
            ?.toIntOrNull() ?: 0
        height = retriever
            .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
            ?.toIntOrNull() ?: 0
        val millis = retriever
            .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            ?.toLongOrNull() ?: 0L
        duration = (millis / 1000L).toInt()
    } catch (_: Throwable) {
        // A file without metadata still sends; TDLib fills in what it can.
    } finally {
        runCatching { retriever.release() }
    }
    val video = TdApi.InputVideo(
        TdApi.InputFileLocal(path),
        null,
        null,
        0,
        intArrayOf(),
        duration,
        width,
        height,
        true,
    )
    val content = TdApi.InputMessageVideo(
        video,
        TdApi.FormattedText(caption.trim(), emptyArray()),
        false,
        null,
        false,
    )
    val reply = if (replyToId > 0L) {
        TdApi.InputMessageReplyToMessage(replyToId, null, 0, null)
    } else {
        null
    }
    client?.send(TdApi.SendMessage(chatId, null, reply, null, null, content)) { replyMsg ->
        main.post {
            if (replyMsg is TdApi.Message) {
                result.success(null)
            } else if (replyMsg is TdApi.Error) {
                emitError(replyMsg.message)
                result.error("tdlib", replyMsg.message, null)
            } else {
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

/** Any file from the document picker, sent as a Telegram document. */
internal fun TelegramEngine.sendDocument(
    chatId: Long,
    path: String,
    caption: String,
    replyToId: Long,
    result: MethodChannel.Result,
) {
    val document = TdApi.InputDocument(
        TdApi.InputFileLocal(path),
        null,
        false,
    )
    val content = TdApi.InputMessageDocument(
        document,
        TdApi.FormattedText(caption.trim(), emptyArray()),
    )
    val reply = if (replyToId > 0L) {
        TdApi.InputMessageReplyToMessage(replyToId, null, 0, null)
    } else {
        null
    }
    client?.send(TdApi.SendMessage(chatId, null, reply, null, null, content)) { replyMsg ->
        main.post {
            if (replyMsg is TdApi.Message) {
                result.success(null)
            } else if (replyMsg is TdApi.Error) {
                emitError(replyMsg.message)
                result.error("tdlib", replyMsg.message, null)
            } else {
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

/**
 * Hands a downloaded Telegram file to whichever app can display it. TDLib
 * stores downloads under the app's private files directory, so the file is
 * shared through a FileProvider URI instead of a raw path.
 */
internal fun TelegramEngine.openLocalFile(path: String, result: MethodChannel.Result) {
    val context = appContext ?: run {
        result.error("file", "The Android context is unavailable", null)
        return
    }
    val file = File(path)
    if (!file.exists()) {
        result.error("file", "The file is not downloaded yet", null)
        return
    }
    try {
        val uri: Uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file,
        )
        val mime = MimeTypeMap.getSingleton()
            .getMimeTypeFromExtension(file.extension.lowercase())
            ?: "*/*"
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
        result.success(null)
    } catch (t: Throwable) {
        result.error("file", "No app can open this file", null)
    }
}
