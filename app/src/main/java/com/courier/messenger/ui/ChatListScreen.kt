package com.courier.messenger.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Create
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.courier.messenger.telegram.TdlibClient
import com.courier.messenger.ui.components.GlassCircleButton
import com.courier.messenger.ui.components.GlassPanel
import com.courier.messenger.ui.theme.IosType
import com.courier.messenger.ui.theme.LocalIos
import kotlin.math.min

/**
 * Chats tab, laid out like the iOS client: large collapsing title, glass
 * compose button, glass search field, pinned/all-chat sections.
 */
@Composable
fun ChatListScreen(
    chats: List<TdlibClient.ChatUi>,
    connection: String,
    onOpenChat: (Long) -> Unit,
) {
    val ios = LocalIos.current
    var query by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    val collapse by remember {
        derivedStateOf {
            if (listState.firstVisibleItemIndex > 0) 1f
            else min(1f, listState.firstVisibleItemScrollOffset / 220f)
        }
    }
    val titleSize = 34f - 6f * collapse
    val titleOffset = (-6f * collapse).dp

    val filtered = remember(chats, query) {
        if (query.isBlank()) chats
        else chats.filter {
            it.title.contains(query, ignoreCase = true) || it.preview.contains(query, ignoreCase = true)
        }
    }
    val pinned = filtered.filter { it.pinned }
    val rest = filtered.filter { !it.pinned }

    Column(Modifier.fillMaxSize().background(ios.background)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 18.dp, end = 14.dp, top = 10.dp, bottom = 2.dp)
                .graphicsLayer { translationY = titleOffset.toPx() },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "Chats",
                style = IosType.largeTitle.copy(fontSize = titleSize.sp, lineHeight = (titleSize + 6f).sp),
                color = ios.textPrimary,
            )
            Spacer(Modifier.weight(1f))
            GlassCircleButton(size = 40.dp) {
                Icon(
                    Icons.Filled.Create,
                    contentDescription = "New message",
                    tint = ios.accent,
                    modifier = Modifier.size(20.dp),
                )
            }
        }

        SearchRow(query = query, onQuery = { query = it })

        if (connection != "Connected") {
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    Modifier
                        .size(7.dp)
                        .background(
                            if (connection.contains("network", true)) ios.danger else ios.badgeMuted,
                            CircleShape,
                        ),
                )
                Spacer(Modifier.width(6.dp))
                Text(connection, style = IosType.footnote, color = ios.textSecondary)
            }
        }

        if (filtered.isEmpty()) {
            EmptyChats(searching = query.isNotBlank())
        } else {
            LazyColumn(state = listState, contentPadding = PaddingValues(bottom = 96.dp)) {
                if (pinned.isNotEmpty()) {
                    item { SectionLabel("Pinned") }
                    items(pinned, key = { it.id }) { chat -> ChatRow(chat, onOpenChat) }
                }
                if (rest.isNotEmpty()) {
                    item { SectionLabel(if (query.isBlank()) "All Chats" else "Results") }
                    items(rest, key = { it.id }) { chat -> ChatRow(chat, onOpenChat) }
                }
            }
        }
    }
}

@Composable
private fun SearchRow(query: String, onQuery: (String) -> Unit) {
    val ios = LocalIos.current
    GlassPanel(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 8.dp),
        shape = RoundedCornerShape(12.dp),
        cornerRadius = 12.dp,
        strength = 0.16f,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().height(38.dp).padding(horizontal = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.Search, contentDescription = null, tint = ios.textSecondary, modifier = Modifier.size(17.dp))
            Spacer(Modifier.width(6.dp))
            Box(Modifier.weight(1f)) {
                if (query.isEmpty()) {
                    Text("Search for messages or users", style = IosType.body, color = ios.textSecondary, maxLines = 1)
                }
                androidx.compose.foundation.text.BasicTextField(
                    value = query,
                    onValueChange = onQuery,
                    singleLine = true,
                    textStyle = IosType.body.copy(color = ios.textPrimary),
                    cursorBrush = androidx.compose.ui.graphics.SolidColor(ios.accent),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    val ios = LocalIos.current
    Text(
        text = text,
        style = IosType.sectionHeader,
        color = ios.textSecondary,
        modifier = Modifier.fillMaxWidth().padding(start = 20.dp, end = 16.dp, top = 12.dp, bottom = 6.dp),
    )
}

@Composable
private fun EmptyChats(searching: Boolean) {
    val ios = LocalIos.current
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                if (searching) "Nothing found" else "No chats yet",
                style = IosType.headline,
                color = ios.textPrimary,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                if (searching) "Try a different search" else "Start a conversation from Contacts",
                style = IosType.subhead,
                color = ios.textSecondary,
            )
        }
    }
}
