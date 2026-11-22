package com.courier.messenger.telegram

import org.drinkless.tdlib.TdApi

/** Pure formatting helpers shared by the chat list and the conversation. */
internal object TdFormat {

    fun name(first: String?, last: String?): String =
        listOfNotNull(first, last).filter { it.isNotBlank() }.joinToString(" ").trim()

    fun initials(title: String): String {
        val words = title.trim().split(Regex("\\s+")).filter { it.isNotBlank() }
        if (words.isEmpty()) return "#"
        return if (words.size == 1) {
            words[0].take(2).replaceFirstChar { it.uppercase() }
        } else {
            "${words[0].take(1)}${words[1].take(1)}".uppercase()
        }
    }

    fun localPath(file: TdApi.File?): String =
        if (file?.local?.isDownloadingCompleted == true) file.local.path else ""

    fun bestPhotoSize(photo: TdApi.Photo?): TdApi.PhotoSize? =
        photo?.sizes?.maxByOrNull { it.width.toLong() * it.height }

    fun contentText(content: TdApi.MessageContent?): String = when (content) {
        null -> ""
        is TdApi.MessageText -> content.text.text
        is TdApi.MessagePhoto -> content.caption.text.ifBlank { "Photo" }
        is TdApi.MessageVideo -> content.caption.text.ifBlank { "Video" }
        is TdApi.MessageAnimation -> content.caption.text.ifBlank { "GIF" }
        is TdApi.MessageDocument -> content.caption.text.ifBlank {
            content.document.fileName.ifBlank { "Document" }
        }
        is TdApi.MessageAudio -> content.caption.text.ifBlank { "Audio" }
        is TdApi.MessageVoiceNote -> content.caption.text.ifBlank { "Voice message" }
        is TdApi.MessageVideoNote -> "Video message"
        is TdApi.MessageSticker -> content.sticker.emoji.ifBlank { "Sticker" }
        is TdApi.MessageLocation -> "Location"
        is TdApi.MessageVenue -> "Venue"
        is TdApi.MessageContact -> "Contact"
        is TdApi.MessagePoll -> content.poll.question.text.ifBlank { "Poll" }
        is TdApi.MessageDice -> content.emoji
        is TdApi.MessageCall -> "Call"
        is TdApi.MessageBasicGroupChatCreate -> "Group created"
        is TdApi.MessageChatAddMembers -> "Members added"
        is TdApi.MessageChatChangeTitle -> "Group renamed"
        is TdApi.MessageChatChangePhoto -> "Photo changed"
        is TdApi.MessageChatDeletePhoto -> "Photo removed"
        is TdApi.MessageChatJoinByLink -> "Joined by link"
        is TdApi.MessageChatJoinByRequest -> "Joined by request"
        is TdApi.MessagePinMessage -> "Pinned message"
        is TdApi.MessageScreenshotTaken -> "Screenshot taken"
        else -> "Message"
    }

    fun preview(message: TdApi.Message?): String {
        if (message == null) return ""
        val text = contentText(message.content)
        return if (message.isOutgoing) "You: $text" else text
    }

    fun kind(content: TdApi.MessageContent?): String = when (content) {
        null -> "other"
        is TdApi.MessageText -> "text"
        is TdApi.MessagePhoto -> "photo"
        is TdApi.MessageVideo -> "video"
        is TdApi.MessageAnimation -> "animation"
        is TdApi.MessageDocument -> "document"
        is TdApi.MessageAudio -> "audio"
        is TdApi.MessageVoiceNote -> "voice"
        is TdApi.MessageVideoNote -> "videoNote"
        is TdApi.MessageSticker -> "sticker"
        is TdApi.MessageLocation -> "location"
        is TdApi.MessageContact -> "contact"
        is TdApi.MessagePoll -> "poll"
        is TdApi.MessageCall -> "call"
        else -> if (isService(content)) "service" else "other"
    }

    fun isService(content: TdApi.MessageContent?): Boolean = when (content) {
        is TdApi.MessageBasicGroupChatCreate -> true
        is TdApi.MessageChatAddMembers -> true
        is TdApi.MessageChatChangeTitle -> true
        is TdApi.MessageChatChangePhoto -> true
        is TdApi.MessageChatDeletePhoto -> true
        is TdApi.MessageChatJoinByLink -> true
        is TdApi.MessageChatJoinByRequest -> true
        is TdApi.MessagePinMessage -> true
        is TdApi.MessageScreenshotTaken -> true
        else -> false
    }

    fun senderName(
        sender: TdApi.MessageSender?,
        users: Map<Long, TdApi.User>,
        chats: Map<Long, TdApi.Chat>,
    ): String = when (sender) {
        is TdApi.MessageSenderUser -> {
            val user = users[sender.userId]
            name(user?.firstName, user?.lastName).ifBlank { "User" }
        }
        is TdApi.MessageSenderChat -> chats[sender.chatId]?.title ?: "Channel"
        else -> ""
    }
}
