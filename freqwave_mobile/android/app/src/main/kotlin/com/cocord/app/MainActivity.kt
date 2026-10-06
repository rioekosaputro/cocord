package com.cocord.app

import android.content.Intent
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.cocord.app/hardware_ptt"
    private var channel: MethodChannel? = null
    private val linkChannelName = "com.cocord.app/links"
    private var linkChannel: MethodChannel? = null
    private var volumeKeyEnabled = true

    // KeyEvent.KEYCODE_PTT (API 35) is referenced by value so older SDKs compile.
    private val KEYCODE_PTT = 286

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "setVolumeKeyEnabled" -> {
                        volumeKeyEnabled = call.arguments as? Boolean ?: true
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        linkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, linkChannelName).also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "initialLink") {
                    result.success(cocordLink(intent))
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    private fun cocordLink(intent: Intent?): String? =
        intent?.dataString?.takeIf { it.startsWith("cocord://") }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        cocordLink(intent)?.let { linkChannel?.invokeMethod("onLink", it) }
    }

    private fun isPttKey(keyCode: Int): Boolean =
        keyCode == KEYCODE_PTT ||
            (volumeKeyEnabled && keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isPttKey(keyCode)) {
            if (event?.repeatCount == 0) {
                channel?.invokeMethod("onPttKeyDown", null)
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (isPttKey(keyCode)) {
            channel?.invokeMethod("onPttKeyUp", null)
            return true
        }
        return super.onKeyUp(keyCode, event)
    }
}
