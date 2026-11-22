package com.courier.messenger.telegram

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.drinkless.tdlib.Client
import org.drinkless.tdlib.TdApi
import java.util.concurrent.ConcurrentHashMap

/**
 * Owns the single TDLib client, the in-memory caches and the update router.
 * Formatting and publishing live in separate files so the bridge stays small
 * enough to reason about.
 */
internal class TelegramEngine(internal val emit: (Map<String, Any?>) -> Unit) {

    internal val chats = ConcurrentHashMap<Long, TdApi.Chat>()
    internal val activeStories = ConcurrentHashMap<Long, TdApi.ChatActiveStories>()
    internal val users = ConcurrentHashMap<Long, TdApi.User>()
    internal val messages = ConcurrentHashMap<Long, MutableList<TdApi.Message>>()
    internal val hasMore = ConcurrentHashMap<Long, Boolean>()
    internal val typingUntil = ConcurrentHashMap<Long, Long>()
    internal val requestedFiles = ConcurrentHashMap.newKeySet<Int>()

    /** Chat folders arrive through `UpdateChatFolders`; keep them for the tabs. */
    internal val chatFolders =
        java.util.concurrent.CopyOnWriteArrayList<TdApi.ChatFolderInfo>()

    internal var client: Client? = null
    internal var appContext: Context? = null
    internal var notifications: CourierNotifications? = null
    internal var apiId = 0
    internal var apiHash = ""
    internal var myId = 0L
    internal var openChatId = 0L

    internal val main = Handler(Looper.getMainLooper())

    internal var stage = "starting"
    internal var authError: String? = null
    internal var busy = false
    internal var codeLength = 5
    internal var passwordHint: String? = null
    internal var myBio = ""

    private var connection = "Connecting…"
    internal var tdlibVersion = ""

    fun attach(context: Context) {
        appContext = context.applicationContext
        if (notifications == null) {
            notifications = CourierNotifications(context.applicationContext)
        }
    }

    /** Creates the TDLib client once; later calls only refresh what exists. */
    @Synchronized
    fun initialize(id: Int, hash: String) {
        apiId = id
        apiHash = hash
        if (client != null) {
            publishSnapshot()
            refreshChats()
            return
        }
        stage = "starting"
        authError = null
        publishAuth()
        try {
            client = Client.create(
                { update -> handleUpdate(update) },
                { error -> Log.e(TAG, "TDLib update handler", error) },
                { error -> Log.e(TAG, "TDLib default handler", error) },
            )
        } catch (t: Throwable) {
            client = null
            stage = "error"
            authError = "TDLib could not start: ${t.message ?: t.javaClass.simpleName}"
            publishAuth()
        }
    }

    fun shutdown() {
        client?.fire(TdApi.Close())
    }

    // -------------------------------------------------------------- updates

    private fun handleUpdate(obj: TdApi.Object?) {
        when (val update = obj) {
            is TdApi.UpdateAuthorizationState -> onAuthorizationState(update.authorizationState)

            is TdApi.UpdateConnectionState -> {
                connection = when (update.state) {
                    is TdApi.ConnectionStateReady -> "Connected"
                    is TdApi.ConnectionStateConnecting -> "Connecting…"
                    is TdApi.ConnectionStateConnectingToProxy -> "Proxy…"
                    is TdApi.ConnectionStateUpdating -> "Updating…"
                    is TdApi.ConnectionStateWaitingForNetwork -> "Waiting for network…"
                    else -> "Offline"
                }
                publishConnection()
            }

            is TdApi.UpdateNewChat -> {
                chats[update.chat.id] = update.chat
                publishChats()
            }

            is TdApi.UpdateChatTitle -> chats[update.chatId]?.let {
                it.title = update.title
                publishChats()
                publishConversationIfOpen(update.chatId)
            }

            is TdApi.UpdateChatPhoto -> chats[update.chatId]?.let {
                it.photo = update.photo
                publishChats()
                publishConversationIfOpen(update.chatId)
            }

            is TdApi.UpdateChatLastMessage -> chats[update.chatId]?.let {
                it.lastMessage = update.lastMessage
                it.positions = update.positions
                publishChats()
                publishConversationIfOpen(update.chatId)
            }

            is TdApi.UpdateChatPosition -> chats[update.chatId]?.let { chat ->
                val kept = chat.positions.filterNot { sameList(it.list, update.position.list) }
                chat.positions = (kept + update.position).toTypedArray()
                publishChats()
            }

            is TdApi.UpdateChatReadInbox -> chats[update.chatId]?.let {
                it.lastReadInboxMessageId = update.lastReadInboxMessageId
                it.unreadCount = update.unreadCount
                publishChats()
                publishConversationIfOpen(update.chatId)
            }

            is TdApi.UpdateChatReadOutbox -> chats[update.chatId]?.let {
                it.lastReadOutboxMessageId = update.lastReadOutboxMessageId
                publishChats()
                publishConversationIfOpen(update.chatId)
            }

            is TdApi.UpdateChatNotificationSettings -> chats[update.chatId]?.let {
                it.notificationSettings = update.notificationSettings
                publishChats()
            }

            is TdApi.UpdateChatAction -> onChatAction(update)
            is TdApi.UpdateChatActiveStories -> onActiveStories(update)
            is TdApi.UpdateChatFolders -> onChatFolders(update)

            is TdApi.UpdateMessageInteractionInfo -> {
                messages[update.chatId]
                    ?.firstOrNull { it.id == update.messageId }
                    ?.let { it.interactionInfo = update.interactionInfo }
                publishConversationIfOpen(update.chatId)
                publishChats()
            }

            is TdApi.UpdateUser -> {
                users[update.user.id] = update.user
                if (update.user.id == myId) publishProfile()
                publishChats()
            }

            is TdApi.UpdateUserStatus -> {
                users[update.userId]?.status = update.status
                publishChats()
                if (update.userId == myId) publishProfile()
            }

            is TdApi.UpdateNewMessage -> {
                notifyMessage(update.message)
                addMessage(update.message)
            }

            is TdApi.UpdateMessageSendSucceeded -> {
                replaceMessage(update.message.chatId, update.oldMessageId, update.message)
                publishChats()
                publishConversationIfOpen(update.message.chatId)
                if (update.message.chatId == openChatId) markRead(update.message.chatId)
            }

            is TdApi.UpdateMessageSendFailed -> {
                replaceMessage(update.message.chatId, update.oldMessageId, update.message)
                emitError(update.error.message)
                publishChats()
                publishConversationIfOpen(update.message.chatId)
            }

            is TdApi.UpdateMessageContent -> {
                messages[update.chatId]?.firstOrNull { it.id == update.messageId }?.let {
                    it.content = update.newContent
                }
                publishConversationIfOpen(update.chatId)
                publishChats()
            }

            is TdApi.UpdateMessageEdited -> {
                messages[update.chatId]?.firstOrNull { it.id == update.messageId }?.let {
                    it.editDate = update.editDate
                }
                publishConversationIfOpen(update.chatId)
            }

            is TdApi.UpdateDeleteMessages -> {
                val list = messages[update.chatId]
                if (list != null) {
                    list.removeAll { message -> update.messageIds.contains(message.id) }
                }
                publishConversationIfOpen(update.chatId)
                publishChats()
            }

            is TdApi.UpdateFile -> publishFile(update.file)

            is TdApi.UpdateOption -> {
                if (update.name == "my_id") {
                    (update.value as? TdApi.OptionValueInteger)?.let { myId = it.value }
                }
                if (update.name == "version") {
                    (update.value as? TdApi.OptionValueString)?.let { tdlibVersion = it.value }
                    publishDebug()
                }
            }

            else -> Unit
        }
    }

    private fun onChatAction(update: TdApi.UpdateChatAction) {
        val fromMe = (update.senderId as? TdApi.MessageSenderUser)?.userId == myId
        if (fromMe) return
        if (update.action is TdApi.ChatActionCancel) {
            typingUntil.remove(update.chatId)
        } else {
            typingUntil[update.chatId] = System.currentTimeMillis() + 6_000
            val chatId = update.chatId
            main.postDelayed({
                if ((typingUntil[chatId] ?: 0L) <= System.currentTimeMillis()) {
                    typingUntil.remove(chatId)
                    publishChats()
                }
            }, 6_500)
        }
        publishChats()
    }

    internal fun addMessage(message: TdApi.Message) {
        val list = messages.getOrPut(message.chatId) { mutableListOf() }
        if (list.none { it.id == message.id }) {
            list.add(message)
            list.sortBy { it.id }
        }
        if (message.chatId == openChatId && !message.isOutgoing) {
            markRead(message.chatId)
        }
        publishChats()
        publishConversationIfOpen(message.chatId)
    }

    private fun replaceMessage(chatId: Long, oldId: Long, message: TdApi.Message) {
        val list = messages.getOrPut(chatId) { mutableListOf() }
        val index = list.indexOfFirst { it.id == oldId }
        if (index >= 0) list[index] = message
        else if (list.none { it.id == message.id }) list.add(message)
        list.sortBy { it.id }
    }

    private fun sameList(a: TdApi.ChatList, b: TdApi.ChatList): Boolean =
        a.javaClass == b.javaClass

    internal fun sendTyping(chatId: Long, typing: Boolean) {
        val action = if (typing) TdApi.ChatActionTyping() else TdApi.ChatActionCancel()
        client?.fire(TdApi.SendChatAction(chatId, null, null, action))
    }

    internal fun emitError(message: String?) {
        if (message.isNullOrBlank()) return
        emit(mapOf("type" to "error", "message" to message))
    }

    internal fun emitDebug() = publishDebug()

    internal fun connectionLabel(): String = connection

    internal fun version(): String = tdlibVersion

    /** Re-sends the whole state, used when Flutter attaches a new event sink. */
    fun publishSnapshot() {
        publishAuth()
        publishProfile()
        publishConnection()
        publishChats()
        publishFolders()
        publishDebug()
        val chatId = openChatId
        if (chatId != 0L) publishConversation(chatId)
    }

    companion object {
        private const val TAG = "Courier/TDLib"
    }
}

/** Fire-and-forget TDLib call: the update stream carries the result. */
internal fun Client.fire(function: TdApi.Function<*>) {
    send(function) { _ -> }
}
