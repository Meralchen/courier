package com.courier.messenger.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.courier.messenger.telegram.Format
import com.courier.messenger.telegram.TdlibClient
import com.courier.messenger.ui.components.Avatar
import com.courier.messenger.ui.components.Hairline
import com.courier.messenger.ui.components.Ticks
import com.courier.messenger.ui.components.UnreadBadge
import com.courier.messenger.ui.theme.IosType
import com.courier.messenger.ui.theme.LocalIos

/**
 * One chat row: 54 pt avatar, semibold title, tick + preview line, timestamp
 * and unread badge, with a spring press-scale and the iOS 79 pt hairline inset.
 */
@Composable
internal fun ChatRow(chat: TdlibClient.ChatUi, onOpenChat: (Long) -> Unit) {
    val ios = LocalIos.current
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.985f else 1f,
        animationSpec = spring(dampingRatio = 0.62f, stiffness = 950f),
        label = "rowScale",
    )
    val rowBackground by animateColorAsState(
        targetValue = if (pressed) ios.accent.copy(alpha = 0.07f) else ios.background,
        label = "rowBg",
    )

    Column(Modifier.background(rowBackground)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .scale(scale)
                .clickable(interactionSource = interaction, indication = null) { onOpenChat(chat.id) }
                .padding(start = 14.dp, end = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.padding(vertical = 8.dp)) {
                Avatar(
                    initials = chat.initials,
                    gradient = Format.gradientFor(chat.id),
                    size = 54.dp,
                )
            }
            Spacer(Modifier.width(11.dp))
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = chat.title,
                        style = IosType.title.copy(color = ios.textPrimary),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (chat.pinned) {
                        Spacer(Modifier.width(4.dp))
                        Text("📌", style = IosType.caption)
                    }
                }
                Spacer(Modifier.height(2.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (chat.lastOutgoing && chat.lastMessageId != 0L) {
                        Ticks(read = true, color = ios.accent)
                        Spacer(Modifier.width(3.dp))
                    }
                    Text(
                        text = chat.preview.ifBlank { "No messages yet" },
                        style = IosType.subhead.copy(color = ios.textSecondary),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            Spacer(Modifier.width(8.dp))
            Column(horizontalAlignment = Alignment.End) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (chat.lastOutgoing && chat.lastMessageId != 0L) {
                        Ticks(read = true, color = ios.accent)
                        Spacer(Modifier.width(3.dp))
                    }
                    Text(
                        text = Format.chatTime(chat.date),
                        style = IosType.caption.copy(fontSize = 12.5.sp),
                        color = if (chat.unread > 0) ios.accent else ios.textSecondary,
                        maxLines = 1,
                    )
                }
                Spacer(Modifier.height(5.dp))
                if (chat.unread > 0) {
                    UnreadBadge(chat.unread, muted = false)
                } else {
                    Spacer(Modifier.height(22.dp))
                }
            }
        }
        Hairline(Modifier.padding(start = 79.dp))
    }
}
