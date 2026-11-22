package com.courier.messenger.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.courier.messenger.telegram.Format
import com.courier.messenger.telegram.TdlibClient
import com.courier.messenger.ui.components.Avatar
import com.courier.messenger.ui.components.ChevronLeft
import com.courier.messenger.ui.components.GlassPanel
import com.courier.messenger.ui.theme.IosType
import com.courier.messenger.ui.theme.LocalIos
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Conversation screen: glass navigation bar, day separators, iOS bubbles and
 * the interactive edge-swipe-back gesture the iOS client uses.
 */
@Composable
fun ChatScreen(chatId: Long, onBack: () -> Unit) {
    val ios = LocalIos.current
    val chat by TdlibClient.activeChat.collectAsState()
    val messagesMap by TdlibClient.messages.collectAsState()
    val messages = messagesMap[chatId].orEmpty()
    val listState = rememberLazyListState()
    val density = LocalDensity.current
    val screenWidth = with(density) { LocalConfiguration.current.screenWidthDp.dp.toPx() }

    var draft by remember { mutableStateOf("") }
    var dragX by remember { mutableFloatStateOf(0f) }

    LaunchedEffect(chatId) { TdlibClient.openChat(chatId) }
    DisposableEffect(chatId) { onDispose { TdlibClient.closeChat() } }
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.lastIndex)
            TdlibClient.markRead(chatId)
        }
    }

    Box(Modifier.fillMaxSize().background(ios.chatBackground)) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .imePadding()
                .graphicsLayer { translationX = dragX }
                .pointerInput(chatId) {
                    detectHorizontalDragGestures(
                        onHorizontalDrag = { change, amount ->
                            change.consume()
                            dragX = (dragX + amount).coerceIn(0f, screenWidth)
                        },
                        onDragEnd = {
                            if (dragX > screenWidth * 0.28f) onBack() else dragX = 0f
                        },
                        onDragCancel = { dragX = 0f },
                    )
                },
        ) {
            ChatHeader(chat = chat, chatId = chatId, onBack = onBack)

            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 10.dp),
            ) {
                itemsIndexed(messages) { index, message ->
                    val previous = messages.getOrNull(index - 1)
                    if (previous == null || !sameDay(previous.date, message.date)) {
                        DaySeparator(message.date)
                    }
                    val next = messages.getOrNull(index + 1)
                    MessageRow(
                        message = message,
                        tail = next == null || next.outgoing != message.outgoing,
                        showSender = !message.outgoing &&
                            (previous == null || previous.sender != message.sender || previous.outgoing),
                    )
                }
            }

            Composer(
                draft = draft,
                onDraft = { draft = it },
                onSend = {
                    val text = draft
                    draft = ""
                    TdlibClient.sendText(chatId, text)
                },
            )
        }
    }
}

@Composable
private fun ChatHeader(chat: TdlibClient.ChatUi?, chatId: Long, onBack: () -> Unit) {
    val ios = LocalIos.current
    GlassPanel(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(bottomStart = 18.dp, bottomEnd = 18.dp),
        cornerRadius = 18.dp,
        strength = 0.30f,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().height(58.dp).padding(horizontal = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(12.dp))
                    .clickable { onBack() }
                    .padding(horizontal = 2.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                ChevronLeft(ios.accent)
                Text("Chats", style = IosType.body, color = ios.accent)
            }
            Spacer(Modifier.width(8.dp))
            Avatar(
                initials = chat?.initials ?: Format.initials(chat?.title ?: "#"),
                gradient = Format.gradientFor(chatId),
                size = 34.dp,
            )
            Spacer(Modifier.width(9.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    text = chat?.title ?: "Chat",
                    style = IosType.title.copy(fontSize = 16.sp),
                    color = ios.textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text("online", style = IosType.caption, color = ios.textSecondary)
            }
        }
    }
}

@Composable
private fun DaySeparator(epochSeconds: Int) {
    val ios = LocalIos.current
    val label = remember(epochSeconds) {
        val format = SimpleDateFormat("d MMMM", Locale.getDefault())
        format.format(Date((if (epochSeconds == 0) System.currentTimeMillis() / 1000 else epochSeconds.toLong()) * 1000L))
    }
    Box(Modifier.fillMaxWidth().padding(vertical = 8.dp), contentAlignment = Alignment.Center) {
        Text(
            text = label,
            style = IosType.caption,
            color = ios.textSecondary,
            modifier = Modifier
                .clip(RoundedCornerShape(10.dp))
                .background(ios.incomingBubble.copy(alpha = 0.55f))
                .padding(horizontal = 10.dp, vertical = 3.dp),
        )
    }
}

private fun sameDay(a: Int, b: Int): Boolean {
    if (a == 0 || b == 0) return a == b
    val calA = java.util.Calendar.getInstance().apply { timeInMillis = a * 1000L }
    val calB = java.util.Calendar.getInstance().apply { timeInMillis = b * 1000L }
    return calA.get(java.util.Calendar.YEAR) == calB.get(java.util.Calendar.YEAR) &&
        calA.get(java.util.Calendar.DAY_OF_YEAR) == calB.get(java.util.Calendar.DAY_OF_YEAR)
}
