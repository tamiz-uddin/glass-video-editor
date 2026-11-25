package com.glass.videoeditor

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import com.google.mediapipe.framework.image.BitmapExtractor
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.selfiesegmenter.SelfieSegmenter
import java.io.File
import java.io.FileOutputStream

class BackgroundRemover(private val context: Context) {

    fun extractMaskSequence(videoPath: String, outDir: File, maxFrames: Int = 240): File? {
        val retriever = MediaMetadataRetriever()
        return try {
            val uri = Uri.parse(videoPath)
            if (uri.scheme == "file") retriever.setDataSource(uri.path!!)
            else retriever.setDataSource(context, uri, null)
            val durationUs =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                    ?.toLongOrNull() ?: return null

            val options = BaseOptions.builder()
                .setModelAssetPath("selfie_segmenter.tflite")
                .build()
            val segmenter = SelfieSegmenter.createFromOptions(
                context,
                SelfieSegmenter.SelfieSegmenterOptions.builder()
                    .setBaseOptions(options)
                    .setRunningMode(RunningMode.IMAGE)
                    .build()
            )

            outDir.mkdirs()
            val stepUs = durationUs / maxFrames.coerceAtLeast(1)
            var frame = 0
            var timeUs = 0L
            while (timeUs < durationUs && frame < maxFrames) {
                val bmp = retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                if (bmp != null) {
                    val mpImage = BitmapImageBuilder(bmp).build()
                    val result = segmenter.segment(mpImage)
                    val masks = result.confidenceMasks()
                    if (masks.isPresent && masks.get().isNotEmpty()) {
                        val maskBitmap = BitmapExtractor.extract(masks.get()[0])
                        FileOutputStream(File(outDir, "mask_${"%04d".format(frame)}.png")).use {
                            maskBitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
                        }
                    }
                    mpImage.close()
                    frame++
                }
                timeUs += stepUs
            }
            segmenter.close()
            retriever.release()
            outDir
        } catch (e: Exception) {
            runCatching { retriever.release() }
            null
        }
    }
}
