package com.glass.videoeditor

import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.glass.videoeditor/video_engine"
    private var pendingResult: MethodChannel.Result? = null

    private val pickVideoLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        val result = pendingResult
        pendingResult = null
        if (uri != null) {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            result?.success(uri.toString())
        } else {
            result?.success(null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickVideo" -> {
                    pendingResult = result
                    pickVideoLauncher.launch(arrayOf("video/*"))
                }
                "probeDuration" -> result.success(0)
                "export" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }
}
