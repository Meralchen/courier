package com.courier.messenger

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.courier.messenger.telegram.CourierTelegramPlugin

/**
 * Single Flutter activity. The Telegram engine lives in a Flutter plugin so it
 * survives configuration changes and keeps one TDLib client per process.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(CourierTelegramPlugin())
    }
}
