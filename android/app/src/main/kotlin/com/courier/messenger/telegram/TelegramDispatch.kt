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
        "editMessage" -> editMessage(
            long("chatId"),
            long("messageId"),
            string("text"),
            result,
        )
        "deleteMessages" -> deleteMessages(long("chatId"), ids("messageIds"), result)
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
        "sessions" -> requestSessions(result)
        "terminateSession" -> terminateSession(long("sessionId"), result)
        "storage" -> requestStorage(result)
        "clearCache" -> clearCache(result)
        else -> result.error("courier", "Unknown method: $method", null)
    }
}
