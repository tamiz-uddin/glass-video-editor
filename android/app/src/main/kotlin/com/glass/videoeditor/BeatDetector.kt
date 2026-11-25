package com.glass.videoeditor

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import java.nio.ByteBuffer

object BeatDetector {

    private const val SAMPLE_RATE = 22050
    private const val WINDOW_MS = 40
    private const val HOP_MS = 20

    fun detectBeats(context: Context, videoPath: String): List<Long> {
        val extractor = MediaExtractor()
        return try {
            val uri = Uri.parse(videoPath)
            if (uri.scheme == "file") extractor.setDataSource(uri.path!!)
            else extractor.setDataSource(context, uri, null)

            var track = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(MediaFormat.KEY_MIME)
                if (mime != null && mime.startsWith("audio/")) {
                    track = i
                    format = f
                    break
                }
            }
            if (track < 0) return emptyList()
            extractor.selectTrack(track)
            val codec = MediaCodec.createDecoderByType(format!!.getString(MediaFormat.KEY_MIME)!!)
            codec.configure(format, null, null, 0)
            codec.start()

            val pcm = mutableListOf<Short>()
            val bufferInfo = MediaCodec.BufferInfo()
            var sawInputEOS = false
            while (!sawInputEOS) {
                val inIndex = codec.dequeueInputBuffer(10000)
                if (inIndex >= 0) {
                    val buf = codec.getInputBuffer(inIndex)!!
                    val size = extractor.readSampleData(buf, 0)
                    if (size < 0) {
                        codec.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        sawInputEOS = true
                    } else {
                        codec.queueInputBuffer(inIndex, 0, size, extractor.sampleTime, 0)
                        extractor.advance()
                    }
                }
                val outIndex = codec.dequeueOutputBuffer(bufferInfo, 10000)
                if (outIndex >= 0) {
                    val out = codec.getOutputBuffer(outIndex)!!
                    val shorts = ShortArray(bufferInfo.size / 2)
                    out.asShortBuffer().get(shorts)
                    pcm.addAll(shorts.toList())
                    codec.releaseOutputBuffer(outIndex, false)
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
            codec.stop()
            codec.release()
            extractor.release()

            detectOnsets(pcm, SAMPLE_RATE)
        } catch (e: Exception) {
            runCatching { extractor.release() }
            emptyList()
        }
    }

    fun detectOnsets(pcm: List<Short>, sampleRate: Int): List<Long> {
        if (pcm.size < sampleRate / 10) return emptyList()
        val window = sampleRate * WINDOW_MS / 1000
        val hop = sampleRate * HOP_MS / 1000
        val energies = mutableListOf<Double>()
        var i = 0
        while (i + window <= pcm.size) {
            var e = 0.0
            for (j in i until i + window) {
                val v = pcm[j] / 32768.0
                e += v * v
            }
            energies.add(e / window)
            i += hop
        }
        if (energies.size < 5) return emptyList()
        val beats = mutableListOf<Long>()
        var mean = energies.reduce { a, b -> a + b } / energies.size
        var prev = energies[0]
        for (k in 1 until energies.size - 1) {
            val cur = energies[k]
            if (cur > mean * 1.5 && cur > prev && energies[k + 1] < cur) {
                beats.add(k * HOP_MS.toLong())
            }
            prev = cur
        }
        return beats
    }
}
