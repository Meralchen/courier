package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi

/**
 * Archived chats and chat folders.
 *
 * TDLib keeps the archive as a second chat list, so the main list must not
 * contain archived chats and the archive screen loads the other list. Folders
 * are pushed by TDLib through `UpdateChatFolders`; the engine caches the
 * `ChatFolderInfo` objects so `ChatListFolder` can be opened on demand.
 */
internal fun TelegramEngine.refreshArchive(depth: Int = 0) {
    val c = client ?: return
    c.send(TdApi.GetChats(TdApi.ChatListArchive(), 100)) { reply ->
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
        c.send(TdApi.LoadChats(TdApi.ChatListArchive(), 100)) { reply ->
            if (reply !is TdApi.Error) refreshArchive(depth + 1)
        }
    }
}

/** Moves a chat between the main list and the archive. */
internal fun TelegramEngine.setArchived(chatId: Long, archived: Boolean) {
    val list: TdApi.ChatList =
        if (archived) TdApi.ChatListArchive() else TdApi.ChatListMain()
    client?.send(TdApi.AddChatToList(chatId, list)) { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
            } else {
                if (archived) refreshArchive() else refreshChats()
            }
        }
    }
}

internal fun TelegramEngine.onChatFolders(update: TdApi.UpdateChatFolders) {
    val cache = chatFolders
    cache.clear()
    cache.addAll(update.chatFolders)
    main.post { publishFolders() }
}

internal fun TelegramEngine.folderPayload(): List<Map<String, Any?>> =
    chatFolders.map { info ->
        mapOf(
            "id" to info.id,
            "title" to info.name.text.text,
            "icon" to info.icon.name,
            "colorId" to info.colorId,
        )
    }

internal fun TelegramEngine.publishFolders() {
    emit(
        mapOf(
            "type" to "folders",
            "folders" to folderPayload(),
        ),
    )
}

internal fun TelegramEngine.requestFolders(result: MethodChannel.Result) {
    result.success(folderPayload())
}

/**
 * Loads the chats of one folder into the shared cache. Membership itself comes
 * from `Chat.chatLists`, which `chatMap` forwards as folder ids.
 */
internal fun TelegramEngine.openFolder(folderId: Int, result: MethodChannel.Result) {
    val info = chatFolders.firstOrNull { it.id == folderId }
    val c = client
    if (info == null || c == null) {
        result.success(null)
        return
    }
    val list = TdApi.ChatListFolder(info.id)
    c.send(TdApi.GetChats(list, 100)) { reply ->
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
    c.send(TdApi.LoadChats(list, 100)) { _ -> }
    result.success(null)
}
