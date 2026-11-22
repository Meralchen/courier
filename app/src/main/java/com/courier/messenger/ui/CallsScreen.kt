package com.courier.messenger.ui

import androidx.compose.foundation.background
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.courier.messenger.ui.theme.IosType
import com.courier.messenger.ui.theme.LocalIos

/**
 * Calls tab. TDLib exposes calls through its own update stream; until that is
 * wired this screen mirrors the iOS empty state instead of inventing history.
 */
@Composable
fun CallsScreen(connection: String) {
    val ios = LocalIos.current
    Column(Modifier.fillMaxSize().background(ios.background)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(start = 18.dp, end = 18.dp, top = 10.dp, bottom = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Calls", style = IosType.largeTitle, color = ios.textPrimary)
        }
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier.size(74.dp).background(ios.accent.copy(alpha = 0.12f), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        Icons.Filled.Phone,
                        contentDescription = null,
                        tint = ios.accent,
                        modifier = Modifier.size(30.dp),
                    )
                }
                Spacer(Modifier.height(14.dp))
                Text("No calls yet", style = IosType.headline, color = ios.textPrimary)
                Spacer(Modifier.height(6.dp))
                Text(
                    "Call history appears here once Telegram calls are enabled.\n$connection",
                    style = IosType.subhead,
                    color = ios.textSecondary,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                )
            }
        }
    }
}
