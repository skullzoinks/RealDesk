package com.example.realdesk

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var hardwareInputPlugin: HardwareInputPlugin? = null
    private var inputInjectionPlugin: InputInjectionPlugin? = null
    private var screenCaptureChannel: MethodChannel? = null
    private lateinit var mediaProjectionManager: MediaProjectionManager
    
    companion object {
        private const val SCREEN_CAPTURE_REQUEST_CODE = 1000
        private const val CHANNEL_NAME = "com.example.realdesk/screen_capture"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        
        hardwareInputPlugin = HardwareInputPlugin(this).also {
            it.startListening(flutterEngine.dartExecutor.binaryMessenger)
        }
        
        inputInjectionPlugin = InputInjectionPlugin(this).also {
            it.startListening(flutterEngine.dartExecutor.binaryMessenger)
        }
        
        screenCaptureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestScreenCapturePermission" -> {
                        requestScreenCapturePermission()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (hardwareInputPlugin?.handleGenericMotion(event) == true) {
            return true
        }
        return super.dispatchGenericMotionEvent(event)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (hardwareInputPlugin?.handleKeyEvent(event) == true) {
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    private fun requestScreenCapturePermission() {
        val captureIntent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(captureIntent, SCREEN_CAPTURE_REQUEST_CODE)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            SCREEN_CAPTURE_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    // Permission granted, start the screen capture service
                    ScreenCaptureService.startService(this, data)
                    screenCaptureChannel?.invokeMethod("onPermissionGranted", null)
                } else {
                    // Permission denied
                    screenCaptureChannel?.invokeMethod("onPermissionDenied", null)
                }
            }
        }
    }

    override fun onDestroy() {
        hardwareInputPlugin?.dispose()
        hardwareInputPlugin = null
        inputInjectionPlugin?.dispose()
        inputInjectionPlugin = null
        screenCaptureChannel = null
        super.onDestroy()
    }
}
