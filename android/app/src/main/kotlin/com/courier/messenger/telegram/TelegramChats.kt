package com.courier.messenger.telegram

import android.graphics.BitmapFactory
import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi

internal fun TelegramEngine.refreshChats(depth: Int = 0) {
    val c = client ?: return
    // The archive is a separate TDLib list but shares the chat cache, so the
    // archive row can be drawn from the same event as the main list.
    if (depth == 0) refreshArchive()
    c.send(TdApi.GetChats(TdApi.ChatListMain(), 200)) { reply ->
        if (reply is TdApi.Chats) {
            reply.chatIds.forEach { id ->
                c.send(TdApi.GetChat(id)) { chat ->
                    if (chat is TdApi.Chat) {
                        chats[id] = chat
                        publishChats()
                    }
                }
            }
            publishChats()
        }
    }
    if (depth < 2) {
        c.send(TdApi.LoadChats(TdApi.ChatListMain(), 200)) { reply ->
            if (reply !is TdApi.Error) refreshChats(depth + 1)
        }
    }
}

internal fun TelegramEngine.openChat(chatId: Long) {
    if (openChatId != 0L && openChatId != chatId) {
        client?.fire(TdApi.CloseChat(openChatId))
    }
    openChatId = chatId
    notifications?.cancel(chatId)
    client?.fire(TdApi.OpenChat(chatId))
    refreshPinned(chatId)
    val cached = messages[chatId]
    if (cached.isNullOrEmpty()) loadHistory(chatId, 0L, null)
    else publishConversation(chatId)
    markRead(chatId)
}

internal fun TelegramEngine.closeChat() {
    if (openChatId != 0L) client?.fire(TdApi.CloseChat(openChatId))
    openChatId = 0L
}

internal fun TelegramEngine.loadHistory(
    chatId: Long,
    fromMessageId: Long,
    result: MethodChannel.Result?,
) {
    client?.send(TdApi.GetChatHistory(chatId, fromMessageId, 0, 50, false)) { reply ->
        main.post {
            if (reply is TdApi.Messages) {
                val list = messages.getOrPut(chatId) { mutableListOf() }
                if (fromMessageId == 0L) list.clear()
                reply.messages.forEach { message ->
                    if (list.none { it.id == message.id }) list.add(message)
                }
                list.sortBy { it.id }
                hasMore[chatId] = reply.messages.size >= 50
                publishConversation(chatId)
                if (chatId == openChatId) markRead(chatId)
                result?.success(null)
            } else if (reply is TdApi.Error) {
                emitError(reply.message)
                result?.error("tdlib", reply.message, null)
            }
        }
    } ?: result?.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.loadMore(chatId: Long, result: MethodChannel.Result) {
    val oldest = messages[chatId]?.minByOrNull { it.id }?.id ?: 0L
    if (oldest == 0L) {
        result.success(null)
        return
    }
    if (hasMore[chatId] == false) {
        result.success(null)
        return
    }
    loadHistory(chatId, oldest, result)
}

/// TDLib has no pinned-message update in this version, so the bar is refreshed
/// whenever a chat opens and after every pin or unpin.
internal fun TelegramEngine.refreshPinned(chatId: Long) {
    client?.send(TdApi.GetChatPinnedMessage(chatId)) { reply ->
        if (reply is TdApi.Message) pinnedMessages[chatId] = reply
        else pinnedMessages.remove(chatId)
        main.post { publishConversationIfOpen(chatId) }
    }
}

internal fun TelegramEngine.pinMessage(
    chatId: Long,
    messageId: Long,
    pinned: Boolean,
    result: MethodChannel.Result,
) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    fun finish(reply: TdApi.Object) {
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                refreshPinned(chatId)
                result.success(null)
            }
        }
    }
    if (pinned) {
        c.send(TdApi.PinChatMessage(chatId, messageId, false, false)) { reply ->
            finish(reply)
        }
    } else {
        c.send(TdApi.UnpinChatMessage(chatId, messageId)) { reply -> finish(reply) }
    }
}

/// Opens (or creates) the private chat with a group member.
internal fun TelegramEngine.openUser(userId: Long, result: MethodChannel.Result) {
    client?.send(TdApi.CreatePrivateChat(userId, true)) { reply ->
        main.post {
            if (reply is TdApi.Chat) {
                chats[reply.id] = reply
                publishChats()
                result.success(reply.id)
            } else if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                result.error("tdlib", "Could not open the profile", null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.markRead(chatId: Long) {
    val ids = messages[chatId]
        ?.sortedByDescending { it.id }
        ?.take(30)
        ?.map { it.id }
        ?.toLongArray()
        ?: return
    if (ids.isEmpty()) return
    client?.fire(TdApi.ViewMessages(chatId, ids, null, true))
    client?.fire(TdApi.ToggleChatIsMarkedAsUnread(chatId, false))
}

internal fun TelegramEngine.sendText(
    chatId: Long,
    text: String,
    replyToId: Long,
    result: MethodChannel.Result,
) {
    val clean = text.trim()
    if (clean.isEmpty()) {
        result.error("empty", "Message is empty", null)
        return
    }
    val reply = if (replyToId > 0L) {
        TdApi.InputMessageReplyToMessage(replyToId, null, 0, null)
    } else {
        null
    }
    val content = TdApi.InputMessageText(
        TdApi.FormattedText(clean, emptyArray()),
        null,
        true,
    )
    client?.send(TdApi.SendMessage(chatId, null, reply, null, null, content)) { replyMsg ->
        main.post {
            sendTyping(chatId, false)
            if (replyMsg is TdApi.Message) result.success(null)
            else if (replyMsg is TdApi.Error) {
                emitError(replyMsg.message)
                result.error("tdlib", replyMsg.message, null)
            } else {
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.sendPhoto(
    chatId: Long,
    path: String,
    caption: String,
    replyToId: Long,
    result: MethodChannel.Result,
) {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    val width = if (bounds.outWidth > 0) bounds.outWidth else 1280
    val height = if (bounds.outHeight > 0) bounds.outHeight else 1280
    val photo = TdApi.InputPhoto(
        TdApi.InputFileLocal(path),
        null,
        null,
        intArrayOf(),
        width,
        height,
    )
    val content = TdApi.InputMessagePhoto(
        photo,
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
            if (replyMsg is TdApi.Message) result.success(null)
            else if (replyMsg is TdApi.Error) {
                emitError(replyMsg.message)
                result.error("tdlib", replyMsg.message, null)
            } else result.success(null)
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.sendVoice(
    chatId: Long,
    path: String,
    duration: Int,
    replyToId: Long,
    result: MethodChannel.Result,
) {
    val note = TdApi.InputVoiceNote(
        TdApi.InputFileLocal(path),
        duration,
        ByteArray(0),
    )
    val content = TdApi.InputMessageVoiceNote(
        note,
        TdApi.FormattedText("", emptyArray()),
        null,
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

internal fun TelegramEngine.forwardMessages(
    fromChatId: Long,
    messageIds: List<Long>,
    toChatId: Long,
    result: MethodChannel.Result,
) {
    if (messageIds.isEmpty()) {
        result.error("forward", "Choose at least one message", null)
        return
    }
    client?.send(
        TdApi.ForwardMessages(
            toChatId,
            null,
            fromChatId,
            messageIds.toLongArray(),
            null,
            false,
            false,
        ),
    ) { reply ->
        main.post {
            if (reply is TdApi.Messages) {
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

internal fun TelegramEngine.editMessage(
    chatId: Long,
    messageId: Long,
    text: String,
    result: MethodChannel.Result,
) {
    val content = TdApi.InputMessageText(
        TdApi.FormattedText(text.trim(), emptyArray()),
        null,
        true,
    )
    client?.send(TdApi.EditMessageText(chatId, messageId, null, content)) { reply ->
        main.post {
            if (reply is TdApi.Error) result.error("tdlib", reply.message, null)
            else result.success(null)
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.deleteMessages(
    chatId: Long,
    ids: List<Long>,
    revoke: Boolean,
    result: MethodChannel.Result,
) {
    if (ids.isEmpty()) {
        result.success(null)
        return
    }
    client?.send(TdApi.DeleteMessages(chatId, ids.toLongArray(), revoke)) { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else result.success(null)
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.setPinned(chatId: Long, pinned: Boolean) {
    client?.fire(TdApi.ToggleChatIsPinned(TdApi.ChatListMain(), chatId, pinned))
}

internal fun TelegramEngine.setMuted(chatId: Long, muted: Boolean) {
    val chat = chats[chatId] ?: return
    val settings = chat.notificationSettings
    settings.useDefaultMuteFor = false
    settings.muteFor = if (muted) Int.MAX_VALUE else 0
    client?.fire(TdApi.SetChatNotificationSettings(chatId, settings))
}

internal fun TelegramEngine.clearHistory(chatId: Long) {
    client?.send(TdApi.DeleteChatHistory(chatId, false, false)) { reply ->
        if (reply is TdApi.Error) emitError(reply.message)
    }
    messages.remove(chatId)
    publishConversation(chatId)
}

internal fun TelegramEngine.deleteChat(chatId: Long) {
    client?.send(TdApi.DeleteChatHistory(chatId, true, false)) { reply ->
        if (reply is TdApi.Error) emitError(reply.message)
    }
    chats.remove(chatId)
    messages.remove(chatId)
    publishChats()
}

internal fun TelegramEngine.openUsername(username: String, result: MethodChannel.Result) {
    val clean = username.trim().removePrefix("@").removePrefix("https://t.me/")
    if (clean.isEmpty()) {
        result.error("username", "Enter a username", null)
        return
    }
    client?.send(TdApi.SearchPublicChat(clean)) { reply ->
        main.post {
            if (reply is TdApi.Chat) {
                chats[reply.id] = reply
                openChat(reply.id)
                publishChats()
                result.success(reply.id)
            } else if (reply is TdApi.Error) {
                result.error("tdlib", reply.message, null)
            } else {
                result.error("tdlib", "Chat not found", null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.downloadFile(fileId: Int) {
    if (fileId == 0) return
    client?.fire(TdApi.DownloadFile(fileId, 8, 0L, 0L, false))
}
