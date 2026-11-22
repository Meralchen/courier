package com.courier.messenger.telegram

import io.flutter.plugin.common.MethodChannel
import org.drinkless.tdlib.TdApi

/** TDLib reaction type to the unicode emoji the bubble can draw. */
internal fun TelegramEngine.reactionEmoji(type: TdApi.ReactionType?): String? =
    when (type) {
        is TdApi.ReactionTypeEmoji -> type.emoji
        else -> null
    }

/**
 * The row of reactions TDLib offers for one message: top reactions first, then
 * the account's recent ones, without duplicates.
 */
internal fun TelegramEngine.requestAvailableReactions(
    chatId: Long,
    messageId: Long,
    result: MethodChannel.Result,
) {
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    c.send(TdApi.GetMessageAvailableReactions(chatId, messageId, 8)) { reply ->
        main.post {
            if (reply is TdApi.AvailableReactions) {
                val seen = LinkedHashSet<String>()
                val rows = ArrayList<Map<String, Any?>>()
                for (reaction in reply.topReactions + reply.recentReactions) {
                    val emoji = reactionEmoji(reaction.type) ?: continue
                    if (!seen.add(emoji)) continue
                    rows.add(
                        mapOf(
                            "emoji" to emoji,
                            "premium" to reaction.needsPremium,
                        ),
                    )
                }
                result.success(rows)
            } else {
                if (reply is TdApi.Error) emitError(reply.message)
                result.success(emptyList<Map<String, Any?>>())
            }
        }
    }
}

/**
 * Adds the reaction, or removes it when the account already chose it. TDLib
 * answers both calls with `Ok`; the message update carries the new counts.
 */
internal fun TelegramEngine.toggleReaction(
    chatId: Long,
    messageId: Long,
    emoji: String,
    result: MethodChannel.Result,
) {
    val chosen = messages[chatId]
        ?.firstOrNull { it.id == messageId }
        ?.interactionInfo
        ?.reactions
        ?.reactions
        ?.any { reaction ->
            reaction.isChosen && reactionEmoji(reaction.type) == emoji
        } == true
    val type = TdApi.ReactionTypeEmoji(emoji)
    val handler: (TdApi.Object) -> Unit = { reply ->
        main.post {
            if (reply is TdApi.Error) {
                emitError(reply.message)
                result.error("tdlib", reply.message, null)
            } else {
                result.success(null)
            }
        }
    }
    val c = client ?: run {
        result.error("tdlib", "TDLib is not running", null)
        return
    }
    if (chosen) {
        c.send(TdApi.RemoveMessageReaction(chatId, messageId, type), handler)
    } else {
        c.send(TdApi.AddMessageReaction(chatId, messageId, type, false, true), handler)
    }
}
