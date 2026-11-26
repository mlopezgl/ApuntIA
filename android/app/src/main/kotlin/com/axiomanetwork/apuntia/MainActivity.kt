package com.axiomanetwork.apuntia

import android.net.Uri
import android.util.AtomicFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val storageExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val snapshot = AtomicFile(File(filesDir, "apuntia-v1.json"))
        MethodChannel(messenger, "com.axiomanetwork.apuntia/storage").setMethodCallHandler { call, result ->
            if (call.method != "read" && call.method != "write") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val value = call.argument<String>("value")
            storageExecutor.execute {
                try {
                    if (call.method == "read") {
                        val raw = try { snapshot.readFully().toString(Charsets.UTF_8) }
                            catch (_: java.io.FileNotFoundException) { null }
                        runOnUiThread { result.success(raw) }
                    } else {
                        requireNotNull(value)
                        val stream = snapshot.startWrite()
                        try {
                            stream.write(value.toByteArray(Charsets.UTF_8))
                            snapshot.finishWrite(stream)
                        } catch (e: Exception) {
                            snapshot.failWrite(stream)
                            throw e
                        }
                        runOnUiThread { result.success(null) }
                    }
                } catch (_: Exception) {
                    runOnUiThread { result.error("storage", "No se pudo acceder al archivo local.", null) }
                }
            }
        }
        MethodChannel(messenger, "com.axiomanetwork.apuntia/ocr").setMethodCallHandler { call, result ->
            if (call.method != "recognize") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("input", "Falta la imagen.", null)
                return@setMethodCallHandler
            }
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            try {
                val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
                recognizer.process(image)
                    .addOnSuccessListener { result.success(it.text) }
                    .addOnFailureListener { result.error("ocr", "No se pudo leer la imagen.", null) }
                    .addOnCompleteListener { recognizer.close() }
            } catch (_: Exception) {
                recognizer.close()
                result.error("ocr", "No se pudo abrir la imagen.", null)
            }
        }
    }

    override fun onDestroy() {
        storageExecutor.shutdown()
        super.onDestroy()
    }
}
