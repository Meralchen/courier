package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi

internal fun TelegramEngine.addMembers(
    chatId: Long,
    userIds: List<Long>,
    result: MethodChannel.Result,
) {
    if (userIds.isEmpty()) {
        result.error("members", "Choose at least one person", null)
        return
    }
    client?.send(TdApi.AddChatMembers(chatId, userIds.toLongArray())) { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.leaveChat(chatId: Long, result: MethodChannel.Result) {
    client?.send(TdApi.LeaveChat(chatId)) { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                chats.remove(chatId)
                messages.remove(chatId)
                pinnedMessages.remove(chatId)
                publishChats()
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.setChatTitle(
    chatId: Long,
    title: String,
    result: MethodChannel.Result,
) {
    val clean = title.trim()
    if (clean.isEmpty()) {
        result.error("title", "Enter a name", null)
        return
    }
    client?.send(TdApi.SetChatTitle(chatId, clean)) { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                refreshChats()
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.setChatDescription(
    chatId: Long,
    description: String,
    result: MethodChannel.Result,
) {
    client?.send(TdApi.SetChatDescription(chatId, description.trim())) { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

/**
 * Creates a supergroup or a broadcast channel. Both are supergroups in TDLib;
 * only the `isChannel` flag differs. Members are added after creation because
 * `AddChatMembers` works on an existing chat id.
 */
internal fun TelegramEngine.createChat(
    title: String,
    userIds: List<Long>,
    isChannel: Boolean,
    result: MethodChannel.Result,
) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    val clean = title.trim()
    if (clean.isEmpty()) {
        result.error("title", "Enter a name", null)
        return
    }
    c.send(
        TdApi.CreateNewSupergroupChat(
            clean,
            false,
            isChannel,
            "",
            null,
            0,
            false,
        ),
    ) { reply ->
        when (reply) {
            is TdApi.Chat -> {
                chats[reply.id] = reply
                val finish: () -> Unit = {
                    main.post {
                        refreshChats()
                        publishChats()
                        result.success(reply.id)
                    }
                }
                if (!isChannel && userIds.isNotEmpty()) {
                    c.send(TdApi.AddChatMembers(reply.id, userIds.toLongArray())) { added ->
                        if (added is TdApi.Error) emitError(added.message)
                        finish()
                    }
                } else {
                    finish()
                }
            }
            is TdApi.Error -> main.post {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            }
            else -> main.post {
                result.error("tdlib", "Could not create the chat", null)
            }
        }
    }
}
