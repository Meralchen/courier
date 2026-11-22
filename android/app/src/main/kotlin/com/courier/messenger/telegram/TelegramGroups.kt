package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi

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
