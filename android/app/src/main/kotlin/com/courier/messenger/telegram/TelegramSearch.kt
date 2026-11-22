package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi
import java.util.Collections
import java.util.concurrent.atomic.AtomicInteger

/**
 * Server-side search, the way Telegram iOS does it: known chats first, then
 * public chats from the whole of Telegram, then matching messages across every
 * chat. The three TDLib requests run in parallel and are folded into one reply.
 */
internal fun TelegramEngine.searchAll(query: String, result: MethodChannel.Result) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    val clean = query.trim()
    if (clean.length < 2) {
        result.success(
            mapOf(
                "chats" to emptyList<Any>(),
                "global" to emptyList<Any>(),
                "messages" to emptyList<Any>(),
            ),
        )
        return
    }

    val localIds = Collections.synchronizedSet(LinkedHashSet<Long>())
    val publicIds = Collections.synchronizedSet(LinkedHashSet<Long>())
    val found = Collections.synchronizedList(mutableListOf<TdApi.Message>())
    val pending = AtomicInteger(3)

    fun completePart() {
        if (pending.decrementAndGet() != 0) return
        val wanted = LinkedHashSet<Long>()
        wanted.addAll(localIds)
        wanted.addAll(publicIds)
        found.forEach { wanted.add(it.chatId) }
        resolveChats(wanted) { resolved ->
            main.post {
                result.success(
                    mapOf(
                        "chats" to localIds.toList().mapNotNull { resolved[it] }
                            .map { chatMap(it) },
                        "global" to publicIds.toList().mapNotNull { resolved[it] }
                            .map { chatMap(it) },
                        "messages" to found.map { message ->
                            val chat = resolved[message.chatId] ?: chats[message.chatId]
                            mapOf(
                                "chatId" to message.chatId,
                                "chatTitle" to (chat?.title ?: ""),
                                "message" to messageMap(message, chat),
                            )
                        },
                    ),
                )
                // Newly resolved chats join the local list so opening a search
                // result has a title, photo and notification state immediately.
                publishChats()
            }
        }
    }

    c.send(TdApi.SearchChats(clean, null, 30)) { reply ->
        if (reply is TdApi.Chats) {
            reply.chatIds.forEach { localIds.add(it) }
        }
        completePart()
    }
    c.send(TdApi.SearchPublicChats(clean, null)) { reply ->
        if (reply is TdApi.Chats) {
            reply.chatIds.forEach { publicIds.add(it) }
        }
        completePart()
    }
    c.send(
        TdApi.SearchMessages(
            TdApi.ChatListMain(),
            clean,
            "",
            30,
            TdApi.SearchMessagesFilterEmpty(),
            null,
            0,
            0,
        ),
    ) { reply ->
        if (reply is TdApi.FoundMessages) {
            reply.messages.forEach { found.add(it) }
        }
        completePart()
    }
}

/**
 * Resolves a set of chat ids through the cache, asking TDLib only for the ones
 * it has never published. The callback always fires, even if TDLib refuses a
 * chat (deleted or inaccessible), so a search never hangs on one id.
 */
private fun TelegramEngine.resolveChats(
    ids: Collection<Long>,
    done: (Map<Long, TdApi.Chat>) -> Unit,
) {
    val c = client ?: run {
        done(emptyMap())
        return
    }
    val resolved = java.util.concurrent.ConcurrentHashMap<Long, TdApi.Chat>()
    val missing = ArrayList<Long>()
    ids.forEach { id ->
        val cached = chats[id]
        if (cached != null) resolved[id] = cached else missing.add(id)
    }
    if (missing.isEmpty()) {
        done(resolved)
        return
    }
    val pending = AtomicInteger(missing.size)
    missing.forEach { id ->
        c.send(TdApi.GetChat(id)) { reply ->
            if (reply is TdApi.Chat) {
                chats[id] = reply
                resolved[id] = reply
            }
            if (pending.decrementAndGet() == 0) done(resolved)
        }
    }
}
