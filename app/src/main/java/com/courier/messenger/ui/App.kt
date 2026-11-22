package com.courier.messenger.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.courier.messenger.BuildConfig
import com.courier.messenger.telegram.AppPrefs
import com.courier.messenger.telegram.TdlibClient
import com.courier.messenger.ui.components.LiquidBackdrop
import com.courier.messenger.ui.theme.LocalIos

/** Tab indices mirror the order of the iOS tab bar. */
internal object Tabs {
    const val Contacts = 0
    const val Calls = 1
    const val Chats = 2
    const val Settings = 3
}

@Composable
fun App(modifier: Modifier = Modifier) {
    val ios = LocalIos.current
    val context = LocalContext.current
    var credentials by remember {
        mutableStateOf(
            AppPrefs.load(
                context = context,
                builtInApiId = BuildConfig.COURIER_API_ID.toIntOrNull(),
                builtInApiHash = BuildConfig.COURIER_API_HASH,
            ),
        )
    }
    val auth by TdlibClient.auth.collectAsState()
    val chats by TdlibClient.chats.collectAsState()
    val profile by TdlibClient.profile.collectAsState()
    val connection by TdlibClient.connection.collectAsState()

    var tab by remember { mutableIntStateOf(Tabs.Chats) }
    var openChatId by remember { mutableStateOf<Long?>(null) }

    LaunchedEffect(credentials) {
        credentials?.let { safe ->
            TdlibClient.initialize(context.applicationContext, safe.apiId, safe.apiHash)
        }
    }

    val stage = when {
        credentials == null -> "setup"
        auth.stage == TdlibClient.Stage.WaitCode -> "code"
        auth.stage == TdlibClient.Stage.WaitPassword -> "password"
        auth.stage == TdlibClient.Stage.Ready -> "app"
        else -> "phone"
    }

    AnimatedContent(
        targetState = stage,
        modifier = modifier.fillMaxSize().background(ios.background),
        transitionSpec = { fadeIn(tween(320)) togetherWith fadeOut(tween(180)) },
        label = "authStage",
    ) { current ->
        when (current) {
            "setup" -> SetupScreen(
                initialId = "",
                initialHash = "",
                onSave = { id, hash ->
                    val parsed = id.toIntOrNull()
                    if (parsed != null) {
                        AppPrefs.save(context, parsed, hash)
                        credentials = com.courier.messenger.telegram.ApiCredentials(parsed, hash)
                    }
                },
            )

            "phone" -> PhoneScreen(auth = auth, onContinue = { TdlibClient.submitPhone(it) })

            "code" -> CodeScreen(
                auth = auth,
                onContinue = { TdlibClient.submitCode(it) },
                onResend = { TdlibClient.resendCode() },
            )

            "password" -> PasswordScreen(auth = auth, onContinue = { TdlibClient.submitPassword(it) })

            else -> MainShell(
                chats = chats,
                profile = profile,
                connection = connection,
                tab = tab,
                onTab = { tab = it },
                openChatId = openChatId,
                onOpenChat = { openChatId = it },
                onCloseChat = { openChatId = null },
                onLogout = { TdlibClient.logout() },
            )
        }
    }
}

@Composable
private fun MainShell(
    chats: List<TdlibClient.ChatUi>,
    profile: TdlibClient.ProfileUi?,
    connection: String,
    tab: Int,
    onTab: (Int) -> Unit,
    openChatId: Long?,
    onOpenChat: (Long) -> Unit,
    onCloseChat: () -> Unit,
    onLogout: () -> Unit,
) {
    val ios = LocalIos.current
    LiquidBackdrop(Modifier.fillMaxSize().background(ios.background)) {
        AnimatedContent(
            targetState = openChatId,
            transitionSpec = {
                (slideInHorizontally(tween(300)) { it } + fadeIn(tween(220))) togetherWith
                    (slideOutHorizontally(tween(260)) { -it / 5 } + fadeOut(tween(170)))
            },
            label = "chatNavigation",
        ) { chatId ->
            if (chatId == null) {
                Column(Modifier.fillMaxSize()) {
                    AnimatedContent(
                        targetState = tab,
                        modifier = Modifier.weight(1f),
                        transitionSpec = { fadeIn(tween(200)) togetherWith fadeOut(tween(140)) },
                        label = "tabs",
                    ) { currentTab ->
                        when (currentTab) {
                            Tabs.Contacts -> ContactsScreen(chats = chats, onOpenChat = onOpenChat)
                            Tabs.Calls -> CallsScreen(connection = connection)
                            Tabs.Chats -> ChatListScreen(
                                chats = chats,
                                connection = connection,
                                onOpenChat = onOpenChat,
                            )
                            else -> SettingsScreen(
                                profile = profile,
                                connection = connection,
                                chatCount = chats.size,
                                onLogout = onLogout,
                            )
                        }
                    }
                    GlassTabBar(
                        selected = tab,
                        unreadChats = chats.count { it.unread > 0 },
                        onSelect = onTab,
                    )
                }
            } else {
                ChatScreen(chatId = chatId, onBack = onCloseChat)
            }
        }
    }
}
