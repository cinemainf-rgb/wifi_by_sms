package com.fazlaka.pay

import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "fazlaka/biometric"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "authenticate") {
                authenticate(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun authenticate(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.success(false)
            return
        }
        val prompt = BiometricPrompt.Builder(this)
            .setTitle("Fazlaka Pay")
            .setSubtitle("حط صباعك عشان تفتح فزلكة")
            .setNegativeButton("إلغاء", mainExecutor) { _, _ ->
                result.success(false)
            }
            .build()
        val cancel = CancellationSignal()
        prompt.authenticate(cancel, mainExecutor, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(r: BiometricPrompt.AuthenticationResult?) {
                result.success(true)
            }
            override fun onAuthenticationFailed() {
                // سيبه يحاول تاني، متقفلهاش
            }
            override fun onAuthenticationError(code: Int, msg: CharSequence?) {
                result.success(false)
            }
        })
    }
}
