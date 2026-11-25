package com.glass.videoeditor

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.StaticOverlay
import androidx.media3.transformer.ClippingConfiguration
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.TransformerException
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.util.concurrent.atomic.AtomicReference

class VideoEngine(private val context: Context) {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var progressSink: EventChannel.EventSink? = null
    private val activeJob = AtomicReference<String?>(null)

    fun setProgressSink(sink: EventChannel.EventSink?) {
        progressSink = sink
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "probeDuration" -> {
                val path = call.argument<String>("path")
                if (path == null) result.success(null) else result.success(probeDurationMs(path))
            }
            "export" -> export(call, result)
            else -> result.notImplemented()
        }
    }

    private fun probeDurationMs(path: String): Long {
        val extractor = MediaExtractor()
        return try {
            val uri = Uri.parse(path)
            if (uri.scheme == "file") {
                extractor.setDataSource(uri.path!!)
            } else {
                extractor.setDataSource(context, uri, null)
            }
            var durationUs = 0L
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME)
                if (mime != null && mime.startsWith("video/")) {
                    durationUs = format.getLong(MediaFormat.KEY_DURATION)
                    break
                }
            }
            extractor.release()
            durationUs / 1000
        } catch (e: Exception) {
            runCatching { extractor.release() }
            0L
        }
    }

    private fun textOverlayBitmap(text: String, fontSize: Double, colorHex: Int, width: Int, height: Int): Bitmap {
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val paint = Paint().apply {
            color = colorHex
            textSize = (fontSize * width / 1080.0).toFloat()
            typeface = Typeface.DEFAULT_BOLD
            isAntiAlias = true
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(text, width / 2f, height * 0.8f, paint)
        return bmp
    }

    private fun export(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as Map<*, *>
            val jobId = args["jobId"] as String
            val project = JSONObject(args["project"] as Map<*, *>)
            val clipsJson = project.getJSONArray("clips")
            val overlaysJson = project.optJSONArray("overlays")
            val width = (args["width"] as Number).toInt()
            val height = (args["height"] as Number).toInt()

            val items = mutableListOf<EditedMediaItem>()
            val clipStarts = mutableListOf<Long>()
            var cursorMs = 0L
            for (i in 0 until clipsJson.length()) {
                val c = clipsJson.getJSONObject(i)
                val uri = Uri.parse(c.getString("path"))
                val startMs = c.optLong("trimStartMs", 0L)
                val endMs = c.optLong("trimEndMs", 0L)
                val speed = c.optDouble("speed", 1.0)

                val clipping = ClippingConfiguration.Builder()
                    .setStartMs(startMs)
                    .apply { if (endMs > 0) setEndMs(endMs) }
                    .build()

                val builder = EditedMediaItem.Builder(MediaItem.fromUri(uri))
                    .setClippingConfiguration(clipping)

                if (overlaysJson != null) {
                    val effects = mutableListOf<androidx.media3.common.Effect>()
                    for (j in 0 until overlaysJson.length()) {
                        val o = overlaysJson.getJSONObject(j)
                        val oStart = o.getLong("startMs")
                        if (oStart in cursorMs until cursorMs + effectiveMs(c, speed)) {
                            val bmp = textOverlayBitmap(
                                o.getString("text"),
                                o.optDouble("fontSize", 28.0),
                                o.optInt("colorHex", -0x1).toInt(),
                                width,
                                height
                            )
                            effects.add(StaticOverlay(bmp, (oStart - cursorMs) * 1000))
                        }
                    }
                    if (effects.isNotEmpty) {
                        builder.setEffects(effects)
                    }
                }

                items.add(builder.build())
                clipStarts.add(cursorMs)
                cursorMs += effectiveMs(c, speed)
            }

            val sequence = EditedMediaItemSequence.Builder(items).build()
            val composition = Composition.Builder(listOf(sequence)).build()

            val outputDir = context.getExternalFilesDir(null) ?: context.cacheDir
            val output = File(outputDir, "export_$jobId.mp4")

            val transformer = Transformer.Builder(context)
                .setVideoMimeType(MimeTypes.VIDEO_H264)
                .build()

            activeJob.set(jobId)
            val holder = Transformer.ProgressHolder()
            transformer.addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition) {
                    activeJob.set(null)
                    sendProgress(jobId, 1.0)
                    result.success(output.absolutePath)
                }

                override fun onError(
                    composition: Composition,
                    exportException: TransformerException,
                    exportResult: ExportResult
                ) {
                    activeJob.set(null)
                    result.error("EXPORT_FAILED", exportException.message ?: "unknown", null)
                }
            })
            transformer.start(holder, composition, output.absolutePath)

            val progressRunnable = object : Runnable {
                override fun run() {
                    if (activeJob.get() != jobId) return
                    try {
                        sendProgress(jobId, transformer.getProgress(holder).toDouble())
                    } catch (_: Exception) {
                    }
                    mainHandler.postDelayed(this, 500)
                }
            }
            mainHandler.post(progressRunnable)
        } catch (e: Exception) {
            result.error("EXPORT_ERROR", e.message, null)
        }
    }

    private fun effectiveMs(c: JSONObject, speed: Double): Long {
        val duration = c.getLong("durationMs")
        val end = c.optLong("trimEndMs", 0L).let { if (it > 0) it else duration }
        val start = c.optLong("trimStartMs", 0L)
        val s = if (speed <= 0) 1.0 else speed
        return ((end - start) / s).toLong()
    }

    private fun sendProgress(jobId: String, progress: Double) {
        mainHandler.post {
            progressSink?.success(mapOf("jobId" to jobId, "progress" to progress.coerceIn(0.0, 1.0)))
        }
    }
}
