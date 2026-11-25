package com.glass.videoeditor

import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.glass.videoeditor/video_engine"
    private val progressChannelName = "com.glass.videoeditor/export_progress"

    private lateinit var engine: VideoEngine
    private var pendingPick: MethodChannel.Result? = null

    private val pickVideosLauncher = registerForActivityResult(
        ActivityResultContracts.OpenMultipleDocuments()
    ) { uris ->
        val result = pendingPick
        pendingPick = null
        if (uris.isNullOrEmpty()) {
            result?.success(emptyList<String>())
        } else {
            uris.forEach {
                runCatching {
                    contentResolver.takePersistableUriPermission(
                        it,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                }
            }
            result?.success(uris.map { uri -> uri.toString() })
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engine = VideoEngine(applicationContext)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickVideos" -> {
                    pendingPick = result
                    pickVideosLauncher.launch(arrayOf("video/*"))
                }
                else -> engine.handle(call, result)
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            progressChannelName
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                engine.setProgressSink(events)
            }

            override fun onCancel(arguments: Any?, events: EventChannel.EventSink?) {
                engine.setProgressSink(null)
            }
        })
    }
}
