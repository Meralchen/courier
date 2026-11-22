package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicInteger
import org.drinkless.tdlib.TdApi

/**
 * Story circles for the chat list.
 *
 * TDLib has no "all stories" call: active stories live per chat, so the engine
 * asks `GetChatActiveStories` for the chats it already holds and keeps the
 * answers in [TelegramEngine.activeStories]. `UpdateChatActiveStories` keeps that
 * cache live (a story being posted or expiring), and every change republishes
 * the whole row.
 */
internal fun TelegramEngine.requestStories(result: MethodChannel.Result) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    val targets = chats.values.filter { chat ->
        chat.type is TdApi.ChatTypePrivate || chat.type is TdApi.ChatTypeSupergroup
    }.take(60)
    if (targets.isEmpty()) {
        result.success(emptyList<Map<String, Any?>>())
        return
    }
    val pending = AtomicInteger(targets.size)
    for (chat in targets) {
        c.send(TdApi.GetChatActiveStories(chat.id)) { reply ->
            if (reply is TdApi.ChatActiveStories) {
                if (reply.stories.isEmpty()) {
                    activeStories.remove(reply.chatId)
                } else {
                    activeStories[reply.chatId] = reply
                }
            }
            if (pending.decrementAndGet() == 0) {
                main.post {
                    val payload = storyPayload()
                    emit(mapOf("type" to "stories", "stories" to payload))
                    result.success(payload)
                }
            }
        }
    }
}

internal fun TelegramEngine.onActiveStories(update: TdApi.UpdateChatActiveStories) {
    val stories = update.activeStories
    if (stories.stories.isEmpty()) {
        activeStories.remove(stories.chatId)
    } else {
        activeStories[stories.chatId] = stories
    }
    val payload = storyPayload()
    main.post { emit(mapOf("type" to "stories", "stories" to payload)) }
}

/** Newest-first story circles, main list only, with their poster's avatar. */
internal fun TelegramEngine.storyPayload(): List<Map<String, Any?>> {
    val rows = ArrayList<Map<String, Any?>>()
    for (stories in activeStories.values) {
        val chat = chats[stories.chatId] ?: continue
        if (stories.stories.isEmpty()) continue
        if (stories.list !is TdApi.StoryListMain) continue
        val newest = stories.stories.maxOfOrNull { it.storyId } ?: continue
        val photo = chat.photo?.small
        ensureDownload(photo)
        rows.add(
            mapOf(
                "chatId" to chat.id,
                "title" to chat.title,
                "photoFileId" to (photo?.id ?: 0),
                "photoPath" to TdFormat.localPath(photo),
                "count" to stories.stories.size,
                "unread" to (newest > stories.maxReadStoryId),
                "order" to stories.order,
            ),
        )
    }
    return rows.sortedByDescending { (it["order"] as? Number)?.toLong() ?: 0L }
}
