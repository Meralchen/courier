package com.courier.messenger.telegram

import org.drinkless.tdlib.TdApi

/** Every payload Flutter receives goes through one of these functions. */
internal fun TelegramEngine.publishAuth() {
    emit(
        mapOf(
            "type" to "auth",
            "stage" to stage,
            "error" to authError,
            "busy" to busy,
            "codeLength" to codeLength,
            "passwordHint" to passwordHint,
        ),
    )
}

internal fun TelegramEngine.publishChats() {
    // A chat belongs to exactly one of the main list and the archive. Publish
    // both, each with the position that carries its pin state, and let the
    // Flutter side split them into the list and the archive row.
    val ordered = chats.values.mapNotNull { chat ->
        val archived = chat.chatLists.any { it is TdApi.ChatListArchive } ||
            chat.positions.any { it.list is TdApi.ChatListArchive }
        val position = chat.positions.firstOrNull {
            if (archived) it.list is TdApi.ChatListArchive else it.list is TdApi.ChatListMain
        } ?: return@mapNotNull null
        chat to position
    }.sortedWith(
        compareByDescending<Pair<TdApi.Chat, TdApi.ChatPosition>> { it.second.isPinned }
            .thenByDescending { it.second.order },
    )
    emit(
        mapOf(
            "type" to "chats",
            "chats" to ordered.map { chatMap(it.first) },
        ),
    )
}

internal fun TelegramEngine.publishConversation(chatId: Long) {
    val list = messages[chatId]?.sortedBy { it.id } ?: emptyList()
    val chat = chats[chatId]
    emit(
        mapOf(
            "type" to "messages",
            "chatId" to chatId,
            "messages" to list.map { messageMap(it, chat) },
            "hasMore" to (hasMore[chatId] ?: false),
            "readOutboxMaxId" to (chat?.lastReadOutboxMessageId ?: 0L),
            "pinned" to pinnedMessages[chatId]?.let { messageMap(it, chat) },
        ),
    )
}

internal fun TelegramEngine.publishConversationIfOpen(chatId: Long) {
    if (chatId == openChatId) publishConversation(chatId)
}

internal fun TelegramEngine.publishProfile() {
    val user = users[myId] ?: return
    emit(
        mapOf(
            "type" to "profile",
            "profile" to mapOf(
                "id" to user.id,
                "firstName" to user.firstName,
                "lastName" to user.lastName,
                "phone" to user.phoneNumber,
                "username" to (user.usernames?.activeUsernames?.firstOrNull() ?: ""),
                "bio" to myBio,
                "premium" to user.isPremium,
                "photoFileId" to (user.profilePhoto?.small?.id ?: 0),
                "photoPath" to TdFormat.localPath(user.profilePhoto?.small),
            ),
        ),
    )
    ensureDownload(user.profilePhoto?.small)
}

internal fun TelegramEngine.publishConnection() {
    emit(
        mapOf(
            "type" to "connection",
            "state" to connectionLabel(),
        ),
    )
}

internal fun TelegramEngine.publishDebug() {
    emit(
        mapOf(
            "type" to "debug",
            "version" to version(),
            "connection" to connectionLabel(),
        ),
    )
}

internal fun TelegramEngine.publishFile(file: TdApi.File) {
    val local = file.local
    if (local == null) return
    val done = local.isDownloadingCompleted
    val active = local.isDownloadingActive
    if (!done && !active) return
    val total = if (file.size > 0) file.size else file.expectedSize
    val progress = if (total > 0) {
        (local.downloadedSize.toDouble() / total.toDouble()).coerceIn(0.0, 1.0)
    } else {
        0.0
    }
    emit(
        mapOf(
            "type" to "file",
            "fileId" to file.id,
            "path" to if (done) local.path else "",
            "progress" to progress,
        ),
    )
}
