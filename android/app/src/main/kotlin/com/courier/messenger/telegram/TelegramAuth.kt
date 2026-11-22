package com.courier.messenger.telegram

import android.os.Build
import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi

internal fun TelegramEngine.onAuthorizationState(state: TdApi.AuthorizationState?) {
    when (state) {
        is TdApi.AuthorizationStateWaitTdlibParameters -> {
            stage = "starting"
            busy = true
            publishAuth()
            val dir = "${appContext?.filesDir?.absolutePath ?: ""}/tdlib"
            client?.send(
                TdApi.SetTdlibParameters(
                    false,
                    "$dir/database",
                    "$dir/files",
                    ByteArray(0),
                    true,
                    true,
                    true,
                    false,
                    apiId,
                    apiHash,
                    "en",
                    "Courier for Android",
                    "Android ${Build.VERSION.RELEASE}",
                    "1.0.0",
                ),
            ) { result -> if (result is TdApi.Error) failAuth(result.message) }
        }

        is TdApi.AuthorizationStateWaitPhoneNumber -> {
            stage = "waitPhone"
            busy = false
            authError = null
            publishAuth()
        }

        is TdApi.AuthorizationStateWaitCode -> {
            stage = "waitCode"
            busy = false
            authError = null
            codeLength = 5
            publishAuth()
        }

        is TdApi.AuthorizationStateWaitPassword -> {
            stage = "waitPassword"
            busy = false
            authError = null
            passwordHint = state.passwordHint
            publishAuth()
        }

        is TdApi.AuthorizationStateReady -> {
            stage = "ready"
            busy = false
            authError = null
            publishAuth()
            client?.send(TdApi.GetMe()) { result ->
                if (result is TdApi.User) {
                    myId = result.id
                    users[result.id] = result
                    publishProfile()
                    client?.send(TdApi.GetUserFullInfo(result.id)) { full ->
                        if (full is TdApi.UserFullInfo) {
                            myBio = full.bio?.text ?: ""
                            publishProfile()
                        }
                    }
                }
            }
            client?.send(TdApi.GetOption("version")) { result ->
                if (result is TdApi.OptionValueString) {
                    tdlibVersion = result.value
                    publishDebug()
                }
            }
            refreshChats()
        }

        is TdApi.AuthorizationStateLoggingOut -> {
            stage = "loggingOut"
            busy = true
            publishAuth()
        }

        is TdApi.AuthorizationStateClosed -> {
            stage = "closed"
            client = null
            chats.clear()
            users.clear()
            messages.clear()
            hasMore.clear()
            publishAuth()
            publishChats()
        }

        is TdApi.AuthorizationStateWaitOtherDeviceConfirmation -> {
            stage = "waitPhone"
            authError = "Confirm the login in your Telegram app"
            publishAuth()
        }

        else -> Unit
    }
}

internal fun TelegramEngine.failAuth(message: String) {
    stage = "error"
    busy = false
    authError = message
    publishAuth()
}

private fun normalizePhone(raw: String): String {
    val digits = raw.filter { it.isDigit() }
    return if (digits.isEmpty()) "" else "+$digits"
}

internal fun TelegramEngine.submitPhone(raw: String, result: MethodChannel.Result) {
    val phone = normalizePhone(raw)
    if (phone.length < 5) {
        result.error("phone", "Enter a valid phone number with country code", null)
        return
    }
    busy = true
    authError = null
    publishAuth()
    val settings = TdApi.PhoneNumberAuthenticationSettings(
        false,
        false,
        false,
        false,
        false,
        null,
        emptyArray(),
    )
    client?.send(TdApi.SetAuthenticationPhoneNumber(phone, settings)) { reply ->
        main.post {
            busy = false
            if (reply is TdApi.Error) {
                authError = reply.message
                publishAuth()
                result.error("tdlib", reply.message, null)
            } else {
                publishAuth()
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.submitCode(code: String, result: MethodChannel.Result) {
    busy = true
    authError = null
    publishAuth()
    client?.send(TdApi.CheckAuthenticationCode(code.trim())) { reply ->
        main.post {
            busy = false
            if (reply is TdApi.Error) {
                authError = reply.message
                publishAuth()
                result.error("tdlib", reply.message, null)
            } else {
                publishAuth()
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.submitPassword(password: String, result: MethodChannel.Result) {
    busy = true
    authError = null
    publishAuth()
    client?.send(TdApi.CheckAuthenticationPassword(password)) { reply ->
        main.post {
            busy = false
            if (reply is TdApi.Error) {
                authError = reply.message
                publishAuth()
                result.error("tdlib", reply.message, null)
            } else {
                publishAuth()
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.resendCode(result: MethodChannel.Result) {
    busy = true
    authError = null
    publishAuth()
    client?.send(TdApi.ResendAuthenticationCode(TdApi.ResendCodeReasonUserRequest())) { reply ->
        main.post {
            busy = false
            if (reply is TdApi.Error) {
                authError = reply.message
                publishAuth()
                result.error("tdlib", reply.message, null)
            } else {
                publishAuth()
                result.success(null)
            }
        }
    } ?: result.error("tdlib", "TDLib is not running", null)
}

internal fun TelegramEngine.logout() {
    busy = true
    authError = null
    stage = "loggingOut"
    publishAuth()
    client?.send(TdApi.LogOut()) { reply ->
        if (reply is TdApi.Error) failAuth(reply.message)
    }
}
