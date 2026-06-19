package net.cheack.tabik

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "net.cheack.tabik/share"
    private var pendingUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            if (call.method == "getSharedUrl") {
                result.success(pendingUrl)
                pendingUrl = null
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        flutterEngine?.dartExecutor?.binaryMessenger?.let {
            MethodChannel(it, channel).invokeMethod("sharedUrl", pendingUrl)
            pendingUrl = null
        }
    }

    private fun handleIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            pendingUrl = intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }
}
