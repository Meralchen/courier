package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel

internal fun TelegramEngine.handle(
    method: String,
    args: Map<String, Any?>,
    result: MethodChannel.Result,
) {
    fun string(key: String): String = args[key]?.toString() ?: ""
    fun long(key: String): Long = (args[key] as? Number)?.toLong() ?: 0L
    fun int(key: String): Int = (args[key] as? Number)?.toInt() ?: 0
    fun bool(key: String): Boolean = args[key] as? Boolean ?: false
    fun ids(key: String): List<Long> =
        (args[key] as? List<*>)?.mapNotNull { (it as? Number)?.toLong() } ?: emptyList()

    when (method) {
        "initialize" -> {
            initialize(int("apiId"), string("apiHash"))
            result.success(null)
        }

        "submitPhone" -> submitPhone(string("phone"), result)
        "submitCode" -> submitCode(string("code"), result)
        "submitPassword" -> submitPassword(string("password"), result)
        "resendCode" -> resendCode(result)
        "logOut" -> {
            logout()
            result.success(null)
        }

        "getChats" -> {
            refreshChats()
            result.success(null)
        }
        "setArchived" -> {
            setArchived(long("chatId"), bool("archived"))
            result.success(null)
        }
        "folders" -> requestFolders(result)
        "openFolder" -> openFolder(int("folderId"), result)
        "gifs" -> requestSavedGifs(result)
        "sendGif" -> sendGif(
            long("chatId"),
            int("fileId"),
            int("width"),
            int("height"),
            int("duration"),
            result,
        )
        "reactions" -> requestAvailableReactions(
            long("chatId"),
            long("messageId"),
            result,
        )
        "react" -> toggleReaction(
            long("chatId"),
            long("messageId"),
            string("emoji"),
            result,
        )
        "openChat" -> {
            openChat(long("chatId"))
            result.success(null)
        }
        "closeChat" -> {
            closeChat()
            result.success(null)
        }
        "loadMore" -> loadMore(long("chatId"), result)
        "sendText" -> sendText(
            long("chatId"),
            string("text"),
            long("replyToId"),
            result,
        )
        "sendPhoto" -> sendPhoto(
            long("chatId"),
            string("path"),
            string("caption"),
            long("replyToId"),
            result,
        )
        "sendVideo" -> sendVideo(
            long("chatId"),
            string("path"),
            string("caption"),
            long("replyToId"),
            result,
        )
        "sendDocument" -> sendDocument(
            long("chatId"),
            string("path"),
            string("caption"),
            long("replyToId"),
            result,
        )
        "openFile" -> openLocalFile(string("path"), result)
        "notificationsSync" -> {
            notificationsEnabled = bool("enabled")
            notificationSounds = bool("sounds")
            result.success(null)
        }
        "sendVoice" -> sendVoice(
            long("chatId"),
            string("path"),
            int("duration"),
            long("replyToId"),
            result,
        )
        "forward" -> forwardMessages(
            long("fromChatId"),
            ids("messageIds"),
            long("toChatId"),
            result,
        )
        "editMessage" -> editMessage(
            long("chatId"),
            long("messageId"),
            string("text"),
            result,
        )
        "deleteMessages" -> deleteMessages(long("chatId"), ids("messageIds"), result)
        "pin" -> pinMessage(
            long("chatId"),
            long("messageId"),
            bool("pinned"),
            result,
        )
        "openUser" -> openUser(long("userId"), result)
        "addMembers" -> addMembers(long("chatId"), ids("userIds"), result)
        "leaveChat" -> leaveChat(long("chatId"), result)
        "setTitle" -> setChatTitle(long("chatId"), string("title"), result)
        "setDescription" -> setChatDescription(
            long("chatId"),
            string("description"),
            result,
        )
        "pinChat" -> {
            setPinned(long("chatId"), bool("pinned"))
            result.success(null)
        }
        "muteChat" -> {
            setMuted(long("chatId"), bool("muted"))
            result.success(null)
        }
        "markRead" -> {
            markRead(long("chatId"))
            result.success(null)
        }
        "clearHistory" -> {
            clearHistory(long("chatId"))
            result.success(null)
        }
        "deleteChat" -> {
            deleteChat(long("chatId"))
            result.success(null)
        }
        "typing" -> {
            sendTyping(long("chatId"), bool("typing"))
            result.success(null)
        }
        "downloadFile" -> {
            downloadFile(int("fileId"))
            result.success(null)
        }
        "openUsername" -> openUsername(string("username"), result)
        "updateProfile" -> updateProfile(
            string("firstName"),
            string("lastName"),
            string("bio"),
            string("username"),
            result,
        )
        "setProfilePhoto" -> setProfilePhoto(string("path"), result)
        "chatInfo" -> requestChatInfo(long("chatId"), result)
        "search" -> searchAll(string("query"), result)
        "createChat" -> createChat(
            string("title"),
            ids("userIds"),
            bool("isChannel"),
            result,
        )
        "sessions" -> requestSessions(result)
        "stories" -> requestStories(result)
        "stickers" -> requestStickers(result)
        "sendSticker" -> sendSticker(
            long("chatId"),
            int("fileId"),
            string("emoji"),
            int("width"),
            int("height"),
            result,
        )
        "savedMessages" -> openSavedMessages(result)
        "terminateSession" -> terminateSession(long("sessionId"), result)
        "storage" -> requestStorage(result)
        "clearCache" -> clearCache(result)
        else -> result.error("courier", "Unknown method: $method", null)
    }
}
