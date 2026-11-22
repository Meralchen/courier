package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi

internal fun TelegramEngine.updateProfile(
    firstName: String,
    lastName: String,
    bio: String,
    username: String,
    result: MethodChannel.Result,
) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    c.send(TdApi.SetName(firstName.trim(), lastName.trim())) { reply ->
        if (reply is TdApi.Error) emitError(reply.message)
    }
    c.send(TdApi.SetBio(bio.trim())) { reply ->
        if (reply is TdApi.Error) emitError(reply.message)
    }
    val cleanUsername = username.trim().removePrefix("@")
    c.send(TdApi.SetUsername(cleanUsername)) { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                client?.send(TdApi.GetMe()) { me ->
                    if (me is TdApi.User) {
                        myId = me.id
                        users[me.id] = me
                        myBio = bio.trim()
                        publishProfile()
                    }
                }
                result.success(null)
            }
        }
    }
}

internal fun TelegramEngine.setProfilePhoto(path: String, result: MethodChannel.Result) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    c.send(
        TdApi.SetProfilePhoto(TdApi.InputChatPhotoStatic(TdApi.InputFileLocal(path)), false),
    ) { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                c.send(TdApi.GetMe()) { me ->
                    if (me is TdApi.User) {
                        myId = me.id
                        users[me.id] = me
                        publishProfile()
                    }
                }
                result.success(null)
            }
        }
    }
}

internal fun TelegramEngine.requestChatInfo(chatId: Long, result: MethodChannel.Result) {
    val chat = chats[chatId] ?: run {
        result.error("tdlib", "Chat is not loaded yet", null)
        return
    }
    val privateType = chat.type as? TdApi.ChatTypePrivate
    val base = HashMap<String, Any?>()
    base["type"] = "chatInfo"
    base["chatId"] = chat.id
    base["title"] = chat.title
    base["about"] = ""
    base["phone"] = ""
    base["username"] = ""
    base["photoFileId"] = (chat.photo?.small?.id ?: 0)
    base["photoPath"] = TdFormat.localPath(chat.photo?.small)
    base["memberCount"] = 0
    base["isPrivate"] = privateType != null
    base["muted"] = chat.notificationSettings.muteFor > 0
    base["pinned"] = chat.positions.any { it.list is TdApi.ChatListMain && it.isPinned }
    base["isBlocked"] = false

    if (privateType == null) {
        emit(mapOf("type" to "chatInfo", "info" to base))
        result.success(null)
        return
    }

    val userId = privateType.userId
    client?.send(TdApi.GetUser(userId)) { userReply ->
        if (userReply is TdApi.User) {
            users[userId] = userReply
            val full = HashMap(base)
            full["title"] = TdFormat.name(userReply.firstName, userReply.lastName)
                .ifBlank { chat.title }
            full["phone"] = userReply.phoneNumber
            full["username"] = userReply.usernames?.activeUsernames?.firstOrNull() ?: ""
            full["photoFileId"] = (userReply.profilePhoto?.small?.id ?: 0)
            full["photoPath"] = TdFormat.localPath(userReply.profilePhoto?.small)
            ensureDownload(userReply.profilePhoto?.small)
            client?.send(TdApi.GetUserFullInfo(userId)) { fullInfo ->
                if (fullInfo is TdApi.UserFullInfo) {
                    full["about"] = fullInfo.bio?.text ?: ""
                }
                emit(mapOf("type" to "chatInfo", "info" to full))
            }
            publishChats()
        } else {
            emit(mapOf("type" to "chatInfo", "info" to base))
        }
    }
    result.success(null)
}

internal fun TelegramEngine.requestSessions(result: MethodChannel.Result) {
    client?.send(TdApi.GetActiveSessions()) { reply ->
        main.post {
            if (reply is TdApi.Sessions) {
                val sessions = reply.sessions.map { session ->
                    mapOf(
                        "id" to session.id,
                        "current" to session.isCurrent,
                        "device" to listOf(session.deviceModel, session.platform)
                            .filter { it.isNotBlank() }
                            .joinToString(" · ")
                            .ifBlank { "Unknown device" },
                        "application" to listOf(
                            session.applicationName,
                            session.applicationVersion,
                        ).filter { it.isNotBlank() }.joinToString(" "),
                        "location" to session.location,
                        "ip" to session.ipAddress,
                        "lastActive" to session.lastActiveDate,
                    )
                }
                result.success(sessions)
            } else if (reply is TdApi.Error) {
                result.error("tdlib", reply.message, null)
            } else {
                result.success(emptyList<Map<String, Any?>>())
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.terminateSession(sessionId: Long, result: MethodChannel.Result) {
    client?.send(TdApi.TerminateSession(sessionId)) { reply ->
        main.post {
            if (reply is TdApi.Error) result.error("tdlib", reply.message, null)
            else result.success(null)
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.requestStorage(result: MethodChannel.Result) {
    client?.send(TdApi.GetStorageStatistics(0)) { reply ->
        main.post {
            if (reply is TdApi.StorageStatistics) {
                val payload = mapOf("size" to reply.size, "count" to reply.count)
                emit(mapOf("type" to "storage", "size" to reply.size, "count" to reply.count))
                result.success(payload)
            } else if (reply is TdApi.Error) {
                result.error("tdlib", reply.message, null)
            } else {
                result.success(mapOf("size" to 0L, "count" to 0))
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.clearCache(result: MethodChannel.Result) {
    client?.send(
        TdApi.OptimizeStorage(0L, 0, 0, 0, null, null, null, false, 0),
    ) { reply ->
        main.post {
            if (reply is TdApi.Error) result.error("tdlib", reply.message, null)
            else requestStorage(result)
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}
