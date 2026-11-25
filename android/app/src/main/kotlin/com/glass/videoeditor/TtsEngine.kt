package com.glass.videoeditor

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.io.File
import java.util.Locale
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class TtsEngine(private val context: Context) {

    fun synthesize(text: String, lang: String, outDir: File): String? {
        val outFile = File(outDir, "tts_${UUID.randomUUID()}.wav")
        val latch = CountDownLatch(1)
        var ok = false
        val tts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts.language = Locale.forLanguageTag(lang.ifEmpty { "en" })
                tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {
                        ok = true
                        latch.countDown()
                    }
                    override fun onError(utteranceId: String?) {
                        latch.countDown()
                    }
                })
                val params = android.os.Bundle()
                ok = tts.synthesizeToFile(text, params, outFile, "utterance") == TextToSpeech.SUCCESS
                if (!ok) latch.countDown()
            } else {
                latch.countDown()
            }
        }
        latch.await(30, TimeUnit.SECONDS)
        tts.shutdown()
        return if (ok && outFile.exists()) outFile.absolutePath else null
    }
}
