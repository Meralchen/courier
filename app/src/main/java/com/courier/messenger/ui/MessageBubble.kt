package com.courier.messenger.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.courier.messenger.telegram.Format
import com.courier.messenger.telegram.TdlibClient
import com.courier.messenger.ui.components.GlassCircleButton
import com.courier.messenger.ui.components.GlassPanel
import com.courier.messenger.ui.components.MicGlyph
import com.courier.messenger.ui.components.SendGlyph
import com.courier.messenger.ui.components.Ticks
import com.courier.messenger.ui.theme.IosType
import com.courier.messenger.ui.theme.LocalIos

/**
 * One message bubble. The last bubble of a run gets a 4 dp trailing corner, the
 * rest stay at 18 dp, which is how the iOS client draws its tails.
 */
@Composable
internal fun MessageRow(message: TdlibClient.MessageUi, tail: Boolean, showSender: Boolean) {
    val ios = LocalIos.current
    val outgoing = message.outgoing
    val bubbleColor = if (outgoing) ios.outgoingBottom else ios.incomingBubble
    val textColor = if (outgoing) ios.outgoingText else ios.textPrimary

    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
        horizontalArrangement = if (outgoing) Arrangement.End else Arrangement.Start,
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = 296.dp)
                .clip(
                    RoundedCornerShape(
                        topStart = 18.dp,
                        topEnd = 18.dp,
                        bottomStart = if (outgoing || !tail) 18.dp else 4.dp,
                        bottomEnd = if (!outgoing || !tail) 18.dp else 4.dp,
                    ),
                )
                .background(bubbleColor)
                .padding(horizontal = 12.dp, vertical = 7.dp),
        ) {
            val senderName = message.sender
            if (showSender && senderName != null) {
                Text(
                    senderName,
                    style = IosType.caption.copy(fontSize = 13.sp),
                    color = ios.accent,
                )
                Spacer(Modifier.height(2.dp))
            }
            Text(
                text = message.text.ifBlank { " " },
                style = IosType.body.copy(fontSize = 16.sp),
                color = textColor,
            )
            Spacer(Modifier.height(3.dp))
            Row(
                modifier = Modifier.align(Alignment.End),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = Format.messageTime(message.date),
                    style = IosType.caption2,
                    color = if (outgoing) textColor.copy(alpha = 0.75f) else ios.textSecondary,
                )
                if (outgoing) {
                    Spacer(Modifier.width(3.dp))
                    Ticks(read = !message.pending, color = textColor.copy(alpha = 0.85f))
                }
            }
        }
    }
}

/** Floating glass composer: attach, field with mic/send swap. */
@Composable
internal fun Composer(draft: String, onDraft: (String) -> Unit, onSend: () -> Unit) {
    val ios = LocalIos.current
    val canSend = draft.isNotBlank()

    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp),
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        GlassCircleButton(size = 40.dp) {
            Text("＋", style = IosType.title.copy(fontSize = 20.sp), color = ios.accent)
        }
        GlassPanel(
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(20.dp),
            cornerRadius = 20.dp,
            strength = 0.24f,
        ) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.weight(1f)) {
                    if (draft.isEmpty()) {
                        Text("Message", style = IosType.body, color = ios.textSecondary)
                    }
                    BasicTextField(
                        value = draft,
                        onValueChange = onDraft,
                        textStyle = IosType.body.copy(color = ios.textPrimary),
                        cursorBrush = SolidColor(ios.accent),
                        maxLines = 5,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                        keyboardActions = KeyboardActions(onSend = { if (canSend) onSend() }),
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
                if (!canSend) {
                    Spacer(Modifier.width(6.dp))
                    MicGlyph(ios.textSecondary)
                }
            }
        }
        if (canSend) {
            SendButton(onSend)
        }
    }
}

@Composable
private fun SendButton(onSend: () -> Unit) {
    val ios = LocalIos.current
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.9f else 1f,
        animationSpec = spring(dampingRatio = 0.5f, stiffness = 900f),
        label = "sendScale",
    )
    Box(
        modifier = Modifier
            .size(40.dp)
            .scale(scale)
            .clip(CircleShape)
            .background(ios.accent)
            .clickable(interactionSource = interaction, indication = null) { onSend() },
        contentAlignment = Alignment.Center,
    ) {
        SendGlyph(Color.White)
    }
}
