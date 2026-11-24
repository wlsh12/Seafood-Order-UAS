package com.example.uts

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "seafood/share")
            .setMethodCallHandler { call, result ->
                if (call.method == "share") {
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, call.arguments as String)
                    }
                    startActivity(Intent.createChooser(send, "Bagikan ringkasan"))
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
