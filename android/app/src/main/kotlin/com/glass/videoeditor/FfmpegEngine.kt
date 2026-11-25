package com.glass.videoeditor

import org.json.JSONObject
import java.io.File

object FfmpegEngine {

    private const val XFADE_SECONDS = 0.5

    fun filterChain(filter: String): String = when (filter) {
        "warm" -> "eq=temperature=3200"
        "cool" -> "eq=temperature=7500"
        "bw" -> "hue=s=0"
        "vivid" -> "eq=saturation=1.4:contrast=1.1"
        "vintage" -> "eq=saturation=0.85:contrast=1.08:brightness=0.02"
        else -> ""
    }

    private fun atempoChain(speed: Double): String {
        var remaining = speed
        val parts = mutableListOf<String>()
        while (remaining > 2.0) {
            parts.add("atempo=2.0")
            remaining /= 2.0
        }
        while (remaining < 0.5) {
            parts.add("atempo=0.5")
            remaining /= 0.5
        }
        parts.add("atempo=$remaining")
        return parts.joinToString(",")
    }

    fun clipDurationSec(c: JSONObject): Double {
        val duration = c.getLong("durationMs")
        val end = c.optLong("trimEndMs", 0L).let { if (it > 0) it else duration }
        val start = c.optLong("trimStartMs", 0L)
        val speed = c.optDouble("speed", 1.0).let { if (it <= 0) 1.0 else it }
        return (end - start) / 1000.0 / speed
    }

    fun needsFfmpeg(project: JSONObject): Boolean {
        val clips = project.getJSONArray("clips")
        for (i in 0 until clips.length()) {
            val c = clips.getJSONObject(i)
            if (c.optDouble("speed", 1.0) != 1.0) return true
            if (c.optString("filter", "none") != "none") return true
            if (c.optString("transition", "none") != "none") return true
            if (c.optBoolean("reverse", false)) return true
            if (c.optDouble("zoom", 1.0) != 1.0) return true
        }
        return false
    }

    fun buildCommand(project: JSONObject, width: Int, height: Int, fps: Int, outPath: String): List<String> {
        val clips = project.getJSONArray("clips")
        val n = clips.length()
        val cmd = mutableListOf("ffmpeg", "-y")
        for (i in 0 until n) {
            cmd += listOf("-i", clips.getJSONObject(i).getString("path"))
        }

        val musicPath = project.optString("musicPath", "")
        val hasMusic = musicPath.isNotEmpty() && musicPath != "null"
        val musicVolume = project.optDouble("musicVolume", 1.0)
        var musicIndex = -1
        if (hasMusic) {
            cmd += listOf("-i", musicPath)
            musicIndex = n
        }

        val filters = mutableListOf<String>()
        val videoLabels = mutableListOf<String>()
        val audioLabels = mutableListOf<String>()

        for (i in 0 until n) {
            val c = clips.getJSONObject(i)
            val start = c.optLong("trimStartMs", 0L) / 1000.0
            val end = c.optLong("trimEndMs", 0L).let {
                if (it > 0) it / 1000.0 else c.getLong("durationMs") / 1000.0
            }
            val speed = c.optDouble("speed", 1.0).let { if (it <= 0) 1.0 else it }

            var vchain = "trim=start=$start:end=$end,setpts=(PTS-STARTPTS)/$speed"
            if (c.optBoolean("reverse", false)) vchain += ",reverse"
            val f = filterChain(c.optString("filter", "none"))
            if (f.isNotEmpty()) vchain += ",$f"
            val zoom = c.optDouble("zoom", 1.0).let { if (it < 1.0) 1.0 else it }
            if (zoom != 1.0) {
                val panX = c.optDouble("panX", 0.0)
                val panY = c.optDouble("panY", 0.0)
                vchain += ",scale=w=$width*$zoom:h=$height*$zoom:force_original_aspect_ratio=decrease," +
                    "crop=$width:$height:(in_w-out_w)/2+($panX*in_w):(in_h-out_h)/2+($panY*in_h)"
            }
            vchain += ",scale=$width:$height:force_original_aspect_ratio=decrease," +
                "pad=$width:$height:(ow-iw)/2:(oh-ih)/2,fps=$fps,format=yuv420p"
            filters += "[$i:v]$vchain[v$i]"
            videoLabels += "[v$i]"

            var achain = "atrim=start=$start:end=$end,asetpts=PTS-STARTPTS,volume=${c.optDouble("volume", 1.0)}"
            if (speed != 1.0) achain += ",${atempoChain(speed)}"
            filters += "[$i:a]$achain[a$i]"
            audioLabels += "[a$i]"
        }

        val hasFade = (0 until n - 1).any { clips.getJSONObject(it).optString("transition", "none") == "fade" }
        if (n == 1) {
            filters += "[v0]null[vout]"
        } else if (hasFade) {
            var prev = "[v0]"
            var offset = clipDurationSec(clips.getJSONObject(0)) - XFADE_SECONDS
            for (i in 1 until n) {
                filters += "$prev[v$i]xfade=transition=fade:duration=$XFADE_SECONDS:offset=$offset[vx$i]"
                prev = "[vx$i]"
                offset += clipDurationSec(clips.getJSONObject(i)) - XFADE_SECONDS
            }
            filters += "$prev null[vout]"
        } else {
            filters += videoLabels.joinToString("") + "concat=n=$n:v=1:a=0[vcat]"
            filters += "[vcat]null[vout]"
        }

        filters += audioLabels.joinToString("") + "concat=n=$n:v=0:a=1[acat]"
        if (hasMusic) {
            filters += "[acat][$musicIndex:a]amix=inputs=2:duration=first:weights=1|$musicVolume[aout]"
        } else {
            filters += "[acat]anull[aout]"
        }

        cmd += listOf("-filter_complex", filters.joinToString(";"))
        cmd += listOf(
            "-map", "[vout]", "-map", "[aout]",
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "23",
            "-c:a", "aac", "-b:a", "192k",
            "-movflags", "+faststart",
            outPath
        )
        return cmd
    }

    fun runExport(
        command: List<String>,
        totalDurationMs: Long,
        onProgress: (Double) -> Unit,
        onDone: (Int) -> Unit
    ) {
        Thread {
            try {
                val process = ProcessBuilder(command).redirectErrorStream(true).start()
                val reader = process.inputStream.bufferedReader()
                var durationSec = totalDurationMs / 1000.0
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    val l = line!!
                    val durMatch = Regex("Duration: (\\d+):(\\d+):(\\d+\\.\\d+)").find(l)
                    if (durMatch != null) {
                        val (_, h, m, s) = durMatch.destructured
                        durationSec = h.toDouble() * 3600 + m.toDouble() * 60 + s.toDouble()
                    }
                    val outMatch = Regex("out_time_ms=(\\d+)").find(l)
                    if (outMatch != null && durationSec > 0) {
                        onProgress((outMatch.groupValues[1].toLong() / 1000.0 / 1000.0 / durationSec).coerceIn(0.0, 0.99))
                    }
                }
                onDone(process.waitFor())
            } catch (e: Exception) {
                onDone(-1)
            }
        }.start()
    }
}
