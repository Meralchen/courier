package com.courier.messenger.telegram

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.drinkless.tdlib.TdApi

/**
 * Android notifications for new Telegram messages. The channel matches the
 * app's importance so a new message heads-up like any messenger, and muted
 * chats never reach the shade.
 */
internal class CourierNotifications(private val context: Context) {

    private val manager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Messages",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "New messages from your Telegram chats"
            enableVibration(true)
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    fun allowed(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    fun show(chatId: Long, title: String, text: String) {
        if (!allowed()) return
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        launch.putExtra(EXTRA_CHAT_ID, chatId)
        val pending = PendingIntent.getActivity(
            context,
            chatId.toInt(),
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()
        manager.notify(chatId.toInt(), notification)
    }

    fun cancel(chatId: Long) {
        manager.cancel(chatId.toInt())
    }

    companion object {
        const val CHANNEL_ID = "courier_messages"
        const val EXTRA_CHAT_ID = "courier_chat_id"
    }
}

/**
 * Posts a notification for an incoming message. Old messages (history synced
 * after a cold start) and muted chats are skipped so the phone is not flooded.
 */
internal fun TelegramEngine.notifyMessage(message: TdApi.Message) {
    if (message.isOutgoing || message.chatId == openChatId) return
    val chat = chats[message.chatId] ?: return
    if (chat.notificationSettings.muteFor > 0) return
    if (message.date * 1000L < System.currentTimeMillis() - 90_000L) return
    val text = TdFormat.contentText(message.content).trim()
    if (text.isEmpty()) return
    val sender = TdFormat.senderName(message.senderId, users, chats)
    val body = when {
        chat.type is TdApi.ChatTypePrivate -> text
        sender.isNotBlank() -> "$sender: $text"
        else -> text
    }
    notifications?.show(message.chatId, chat.title, body)
}
