package com.courier.messenger.telegram

import org.drinkless.tdlib.TdApi

internal fun TelegramEngine.ensureDownload(file: TdApi.File?, priority: Int = 1) {
    if (file == null || file.id == 0) return
    if (file.local?.isDownloadingCompleted == true) return
    if (!requestedFiles.add(file.id)) return
    client?.fire(TdApi.DownloadFile(file.id, priority, 0L, 0L, false))
}

internal fun TelegramEngine.chatMap(chat: TdApi.Chat): Map<String, Any?> {
    val last = chat.lastMessage
    val archived = chat.chatLists.any { it is TdApi.ChatListArchive } ||
        chat.positions.any { it.list is TdApi.ChatListArchive }
    val position = chat.positions.firstOrNull {
        if (archived) it.list is TdApi.ChatListArchive else it.list is TdApi.ChatListMain
    }
    val folders = chat.chatLists
        .filterIsInstance<TdApi.ChatListFolder>()
        .map { it.chatFolderId }
    val user = (chat.type as? TdApi.ChatTypePrivate)?.let { users[it.userId] }
    val photo = chat.photo?.small ?: user?.profilePhoto?.small
    ensureDownload(photo)
    return mapOf(
        "id" to chat.id,
        "title" to chat.title,
        "preview" to TdFormat.preview(last),
        "date" to (last?.date ?: 0),
        "unread" to chat.unreadCount,
        "pinned" to (position?.isPinned == true),
        "muted" to (chat.notificationSettings.muteFor > 0),
        "isPrivate" to (chat.type is TdApi.ChatTypePrivate),
        "isGroup" to (chat.type is TdApi.ChatTypeBasicGroup || chat.type is TdApi.ChatTypeSupergroup),
        "userId" to (user?.id ?: 0L),
        "online" to (user?.status is TdApi.UserStatusOnline),
        "typing" to ((typingUntil[chat.id] ?: 0L) > System.currentTimeMillis()),
        "photoFileId" to (photo?.id ?: 0),
        "photoPath" to TdFormat.localPath(photo),
        "lastOutgoing" to (last?.isOutgoing == true),
        "lastMessageId" to (last?.id ?: 0L),
        "readOutboxMaxId" to chat.lastReadOutboxMessageId,
        "readInboxMaxId" to chat.lastReadInboxMessageId,
        "unreadMention" to (chat.unreadMentionCount > 0),
        "memberCount" to 0,
        "lastSeen" to ((user?.status as? TdApi.UserStatusOffline)?.wasOnline ?: 0),
        "archived" to archived,
        "folders" to folders,
    )
}

internal fun TelegramEngine.messageMap(
    message: TdApi.Message,
    chat: TdApi.Chat?,
): Map<String, Any?> {
    val content = message.content
    var text = TdFormat.contentText(content)
    var file: TdApi.File? = null
    // The full attachment (video, document, audio, voice) as opposed to the
    // small thumbnail used for the bubble. Downloading and opening a media
    // message must use this file, not its preview.
    var mediaFile: TdApi.File? = null
    var width = 0
    var height = 0
    var fileName = ""
    var fileSize = 0
    var duration = 0

    when (content) {
        is TdApi.MessagePhoto -> {
            val size = TdFormat.bestPhotoSize(content.photo)
            file = size?.photo
            mediaFile = size?.photo
            width = size?.width ?: 0
            height = size?.height ?: 0
            text = content.caption.text
        }
        is TdApi.MessageVideo -> {
            file = content.video.thumbnail?.file ?: content.video.video
            mediaFile = content.video.video
            width = content.video.width
            height = content.video.height
            duration = content.video.duration
            fileName = content.video.fileName
            text = content.caption.text
        }
        is TdApi.MessageAnimation -> {
            file = content.animation.thumbnail?.file ?: content.animation.animation
            mediaFile = content.animation.animation
            width = content.animation.width
            height = content.animation.height
            duration = content.animation.duration
            fileName = content.animation.fileName
            text = content.caption.text
        }
        is TdApi.MessageDocument -> {
            file = content.document.document
            mediaFile = content.document.document
            fileName = content.document.fileName
            text = content.caption.text
        }
        is TdApi.MessageAudio -> {
            file = content.audio.audio
            mediaFile = content.audio.audio
            fileName = content.audio.fileName
            duration = content.audio.duration
            text = content.caption.text
        }
        is TdApi.MessageVoiceNote -> {
            file = content.voiceNote.voice
            mediaFile = content.voiceNote.voice
            duration = content.voiceNote.duration
        }
        is TdApi.MessageVideoNote -> {
            file = content.videoNote.video
            mediaFile = content.videoNote.video
            width = content.videoNote.thumbnail?.width ?: 0
            height = content.videoNote.thumbnail?.height ?: 0
            duration = content.videoNote.duration
        }
        is TdApi.MessageSticker -> {
            file = content.sticker.sticker
            mediaFile = content.sticker.sticker
            width = content.sticker.width
            height = content.sticker.height
        }
        else -> Unit
    }

    fileSize = ((file?.size ?: 0L).coerceAtMost(Int.MAX_VALUE.toLong())).toInt()
    val reply = message.replyTo as? TdApi.MessageReplyToMessage
    val replied = reply?.let { r ->
        messages[message.chatId]?.firstOrNull { it.id == r.messageId }
    }
    val sender = if (message.isOutgoing) "" else {
        TdFormat.senderName(message.senderId, users, chats)
    }
    val readOutbox = chat?.lastReadOutboxMessageId ?: 0L

    return mapOf(
        "id" to message.id,
        "chatId" to message.chatId,
        "text" to text,
        "date" to message.date,
        "outgoing" to message.isOutgoing,
        "pending" to (message.sendingState is TdApi.MessageSendingStatePending),
        "failed" to (message.sendingState is TdApi.MessageSendingStateFailed),
        "sender" to sender,
        "senderId" to ((message.senderId as? TdApi.MessageSenderUser)?.userId ?: 0L),
        "kind" to TdFormat.kind(content),
        "photoFileId" to (file?.id ?: 0),
        "photoPath" to TdFormat.localPath(file),
        "mediaFileId" to (mediaFile?.id ?: 0),
        "mediaPath" to TdFormat.localPath(mediaFile),
        "width" to width,
        "height" to height,
        "fileName" to fileName,
        "fileSize" to fileSize,
        "duration" to duration,
        "edited" to (message.editDate > 0),
        "replyToId" to (reply?.messageId ?: 0L),
        "replyToText" to (replied?.let { TdFormat.contentText(it.content) } ?: ""),
        "replyToSender" to (replied?.let {
            TdFormat.senderName(it.senderId, users, chats)
        } ?: ""),
        "albumId" to message.mediaAlbumId,
        "isService" to TdFormat.isService(content),
        "read" to (message.id <= readOutbox),
        "isChannelPost" to message.isChannelPost,
        "reactions" to (message.interactionInfo?.reactions?.reactions ?: emptyArray<TdApi.MessageReaction>())
            .mapNotNull { reaction ->
                val emoji = reactionEmoji(reaction.type) ?: return@mapNotNull null
                mapOf(
                    "emoji" to emoji,
                    "count" to reaction.totalCount,
                    "chosen" to reaction.isChosen,
                )
            },
    )
}
