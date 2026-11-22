package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi
import java.util.concurrent.atomic.AtomicInteger

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

internal fun TelegramEngine.openSavedMessages(result: MethodChannel.Result) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    val me = myId
    if (me == 0L) {
        result.error("tdlib", "Profile is not loaded yet", null)
        return
    }
    c.send(TdApi.CreatePrivateChat(me, false)) { chat ->
        main.post {
            when (chat) {
                is TdApi.Chat -> {
                    chats[chat.id] = chat
                    result.success(chat.id)
                }
                is TdApi.Error -> result.error("tdlib", chat.message, null)
                else -> result.error("tdlib", "Could not open Saved Messages", null)
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
    base["members"] = emptyList<Any>()

    if (privateType == null) {
        requestGroupInfo(chat, base, result)
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

/// Groups and channels: description, subscriber/member count and a member
/// list resolved into the same avatars the chat list uses.
private fun TelegramEngine.requestGroupInfo(
    chat: TdApi.Chat,
    base: HashMap<String, Any?>,
    result: MethodChannel.Result,
) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    when (val type = chat.type) {
        is TdApi.ChatTypeSupergroup -> {
            c.send(TdApi.GetSupergroupFullInfo(type.supergroupId)) { full ->
                val info = HashMap(base)
                var total = 0
                if (full is TdApi.SupergroupFullInfo) {
                    info["about"] = full.description
                    total = full.memberCount
                }
                c.send(
                    TdApi.GetSupergroupMembers(
                        type.supergroupId,
                        TdApi.SupergroupMembersFilterRecent(),
                        0,
                        50,
                    ),
                ) { members ->
                    if (members is TdApi.ChatMembers) {
                        if (members.totalCount > 0) total = members.totalCount
                        info["memberCount"] = total
                        resolveMembers(memberIds(members.members), info, result)
                    } else {
                        info["memberCount"] = total
                        resolveMembers(emptyList(), info, result)
                    }
                }
            }
        }
        is TdApi.ChatTypeBasicGroup -> {
            c.send(TdApi.GetBasicGroupFullInfo(type.basicGroupId)) { full ->
                val info = HashMap(base)
                val basic = full as? TdApi.BasicGroupFullInfo
                val members = basic?.members ?: emptyArray()
                info["about"] = basic?.description ?: ""
                info["memberCount"] = members.size
                resolveMembers(memberIds(members), info, result)
            }
        }
        else -> {
            emit(mapOf("type" to "chatInfo", "info" to base))
            result.success(null)
        }
    }
}

private fun memberIds(members: Array<TdApi.ChatMember>): List<Long> =
    members
        .mapNotNull { (it.memberId as? TdApi.MessageSenderUser)?.userId }
        .distinct()
        .take(50)

private fun TelegramEngine.resolveMembers(
    ids: List<Long>,
    info: HashMap<String, Any?>,
    result: MethodChannel.Result,
) {
    if (ids.isEmpty()) {
        finishMembers(ids, emptyMap(), info, result)
        return
    }
    val resolved = java.util.concurrent.ConcurrentHashMap<Long, TdApi.User>()
    val pending = AtomicInteger(ids.size)
    ids.forEach { id ->
        val cached = users[id]
        if (cached != null) {
            resolved[id] = cached
            if (pending.decrementAndGet() == 0) {
                finishMembers(ids, resolved, info, result)
            }
        } else {
            client?.send(TdApi.GetUser(id)) { reply ->
                if (reply is TdApi.User) {
                    users[id] = reply
                    resolved[id] = reply
                }
                if (pending.decrementAndGet() == 0) {
                    finishMembers(ids, resolved, info, result)
                }
            } ?: run {
                if (pending.decrementAndGet() == 0) {
                    finishMembers(ids, resolved, info, result)
                }
            }
        }
    }
}

private fun TelegramEngine.finishMembers(
    ids: List<Long>,
    resolved: Map<Long, TdApi.User>,
    info: HashMap<String, Any?>,
    result: MethodChannel.Result,
) {
    val list = ids.mapNotNull { id ->
        val user = resolved[id] ?: return@mapNotNull null
        val photo = user.profilePhoto?.small
        ensureDownload(photo)
        mapOf(
            "userId" to user.id,
            "title" to TdFormat.name(user.firstName, user.lastName)
                .ifBlank { "Member" },
            "username" to (user.usernames?.activeUsernames?.firstOrNull() ?: ""),
            "photoFileId" to (photo?.id ?: 0),
            "photoPath" to TdFormat.localPath(photo),
            "online" to (user.status is TdApi.UserStatusOnline),
            "lastSeen" to ((user.status as? TdApi.UserStatusOffline)?.wasOnline ?: 0),
        )
    }
    info["members"] = list
    main.post {
        emit(mapOf("type" to "chatInfo", "info" to info))
        result.success(null)
    }
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
