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
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.courier.messenger.ui.components.BubbleGlyph
import com.courier.messenger.ui.components.GlassPanel
import com.courier.messenger.ui.components.PhoneGlyph
import com.courier.messenger.ui.theme.IosType
import com.courier.messenger.ui.theme.LocalIos

/**
 * Floating glass tab bar. The selected item sits in its own lighter pill; the
 * bar itself is a blurred capsule with a specular rim, like iOS 18+.
 */
@Composable
internal fun GlassTabBar(selected: Int, unreadChats: Int, onSelect: (Int) -> Unit) {
    Box(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 8.dp)) {
        GlassPanel(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(30.dp),
            cornerRadius = 30.dp,
            strength = 0.28f,
        ) {
            Row(
                modifier = Modifier.fillMaxWidth().height(62.dp).padding(horizontal = 6.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                TabItem("Contacts", Tabs.Contacts, selected, onSelect, Modifier.weight(1f)) { color ->
                    Icon(Icons.Filled.Person, contentDescription = null, tint = color, modifier = Modifier.size(25.dp))
                }
                TabItem("Calls", Tabs.Calls, selected, onSelect, Modifier.weight(1f)) { color ->
                    PhoneGlyph(color, size = 24.dp)
                }
                TabItem(
                    "Chats",
                    Tabs.Chats,
                    selected,
                    onSelect,
                    Modifier.weight(1f),
                    badge = unreadChats,
                ) { color ->
                    BubbleGlyph(color, filled = selected == Tabs.Chats, size = 25.dp)
                }
                TabItem("Settings", Tabs.Settings, selected, onSelect, Modifier.weight(1f)) { color ->
                    Icon(Icons.Filled.Settings, contentDescription = null, tint = color, modifier = Modifier.size(25.dp))
                }
            }
        }
    }
}

@Composable
private fun TabItem(
    label: String,
    index: Int,
    selected: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
    badge: Int = 0,
    icon: @Composable (Color) -> Unit,
) {
    val ios = LocalIos.current
    val isSelected = selected == index
    val color = if (isSelected) ios.accent else ios.textSecondary
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = when {
            pressed -> 0.9f
            isSelected -> 1.06f
            else -> 1f
        },
        animationSpec = spring(dampingRatio = 0.5f, stiffness = 640f),
        label = "tabScale",
    )

    Box(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 2.dp)
            .clickable(interactionSource = interaction, indication = null) { onSelect(index) },
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .scale(scale)
                .background(
                    if (isSelected) Color.White.copy(alpha = if (ios.isDark) 0.10f else 0.55f) else Color.Transparent,
                    RoundedCornerShape(22.dp),
                )
                .padding(horizontal = 10.dp, vertical = 5.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Box {
                icon(color)
                if (badge > 0) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .size(15.dp)
                            .background(ios.danger, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = if (badge > 99) "99" else badge.toString(),
                            style = IosType.caption2.copy(fontSize = 9.sp),
                            color = Color.White,
                        )
                    }
                }
            }
            Spacer(Modifier.height(2.dp))
            Text(text = label, style = IosType.tabLabel, color = color, maxLines = 1)
        }
    }
}
