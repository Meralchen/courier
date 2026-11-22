package com.courier.messenger.telegram

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Flutter <-> TDLib bridge.
 *
 * One method channel for commands, one event channel for the state stream.
 * TDLib calls back on its own threads, so every reply is posted to the main
 * thread before it touches Flutter.
 */
class CourierTelegramPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private var channel: MethodChannel? = null
    private var events: EventChannel? = null
    private var sink: EventChannel.EventSink? = null
    private var engine: TelegramEngine? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val tg = TelegramEngine { payload ->
            Handler(Looper.getMainLooper()).post { sink?.success(payload) }
        }
        tg.attach(binding.applicationContext)
        engine = tg
        channel = MethodChannel(binding.binaryMessenger, METHODS).also {
            it.setMethodCallHandler(this)
        }
        events = EventChannel(binding.binaryMessenger, EVENTS).also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        channel = null
        events = null
        sink = null
        engine = null
    }

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
        sink = eventSink
        engine?.publishSnapshot()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val tg = engine
        if (tg == null) {
            result.error("courier", "Telegram engine is not attached", null)
            return
        }
        try {
            val args = (call.arguments as? Map<*, *>)?.entries?.associate {
                it.key.toString() to it.value
            } ?: emptyMap()
            tg.handle(call.method, args, result)
        } catch (t: Throwable) {
            result.error("courier", t.message ?: t.javaClass.simpleName, null)
        }
    }

    companion object {
        const val METHODS = "courier/telegram"
        const val EVENTS = "courier/telegram/events"
    }
}
