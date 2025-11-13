package com.example.realdesk

import android.accessibilityservice.AccessibilityService
import android.app.Activity
import android.content.Context
import android.view.InputDevice
import android.view.KeyCharacterMap
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.ViewConfiguration
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin for injecting input events received from remote controller
 * Handles mouse, keyboard, and touch input injection
 */
class InputInjectionPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        private const val CHANNEL = "realdesk/input_injection"
        private const val TAG = "InputInjectionPlugin"
    }

    private var channel: MethodChannel? = null
    private var displayWidth = 0
    private var displayHeight = 0

    fun startListening(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL)
        channel?.setMethodCallHandler(this)
        
        // Get display dimensions
        val display = activity.windowManager.defaultDisplay
        val size = android.graphics.Point()
        display.getRealSize(size)
        displayWidth = size.x
        displayHeight = size.y
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                result.success(true)
            }
            "injectMouseAbs" -> {
                val x = call.argument<Double>("x") ?: 0.0
                val y = call.argument<Double>("y") ?: 0.0
                val displayW = call.argument<Int>("displayW") ?: displayWidth
                val displayH = call.argument<Int>("displayH") ?: displayHeight
                val buttons = call.argument<Int>("buttons") ?: 0
                
                injectMouseAbsolute(x, y, displayW, displayH, buttons)
                result.success(null)
            }
            "injectMouseRel" -> {
                val dx = call.argument<Double>("dx") ?: 0.0
                val dy = call.argument<Double>("dy") ?: 0.0
                val buttons = call.argument<Int>("buttons") ?: 0
                
                injectMouseRelative(dx, dy, buttons)
                result.success(null)
            }
            "injectWheel" -> {
                val dx = call.argument<Double>("dx") ?: 0.0
                val dy = call.argument<Double>("dy") ?: 0.0
                
                injectMouseWheel(dx, dy)
                result.success(null)
            }
            "injectKeyboard" -> {
                val key = call.argument<String>("key") ?: ""
                val code = call.argument<Int>("code") ?: 0
                val down = call.argument<Boolean>("down") ?: false
                val mods = call.argument<Int>("mods") ?: 0
                
                injectKeyboard(key, code, down, mods)
                result.success(null)
            }
            "injectTouch" -> {
                val touches = call.argument<List<Map<String, Any>>>("touches")
                if (touches != null) {
                    injectTouch(touches)
                }
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun injectMouseAbsolute(x: Double, y: Double, displayW: Int, displayH: Int, buttons: Int) {
        // Scale coordinates from remote display to local display
        val scaledX = (x / displayW) * displayWidth
        val scaledY = (y / displayH) * displayHeight
        
        val action = if (buttons != 0) MotionEvent.ACTION_MOVE else MotionEvent.ACTION_HOVER_MOVE
        val eventTime = android.os.SystemClock.uptimeMillis()
        
        val event = MotionEvent.obtain(
            eventTime,
            eventTime,
            action,
            scaledX.toFloat(),
            scaledY.toFloat(),
            0
        )
        
        activity.runOnUiThread {
            activity.dispatchTouchEvent(event)
        }
        
        event.recycle()
    }

    private fun injectMouseRelative(dx: Double, dy: Double, buttons: Int) {
        // Relative mouse movement - accumulate position changes
        // This is more complex and typically requires tracking cursor position
        // For now, we'll log it as not fully implemented
        android.util.Log.d(TAG, "Mouse relative: dx=$dx, dy=$dy, buttons=$buttons")
    }

    private fun injectMouseWheel(dx: Double, dy: Double) {
        // Inject scroll event
        val eventTime = android.os.SystemClock.uptimeMillis()
        
        val event = MotionEvent.obtain(
            eventTime,
            eventTime,
            MotionEvent.ACTION_SCROLL,
            0f,
            0f,
            0
        )
        
        activity.runOnUiThread {
            activity.dispatchGenericMotionEvent(event)
        }
        
        event.recycle()
    }

    private fun injectKeyboard(key: String, code: Int, down: Boolean, mods: Int) {
        val action = if (down) KeyEvent.ACTION_DOWN else KeyEvent.ACTION_UP
        val eventTime = android.os.SystemClock.uptimeMillis()
        
        // Map modifiers
        var metaState = 0
        if ((mods and 1) != 0) metaState = metaState or KeyEvent.META_CTRL_ON
        if ((mods and 2) != 0) metaState = metaState or KeyEvent.META_ALT_ON
        if ((mods and 4) != 0) metaState = metaState or KeyEvent.META_SHIFT_ON
        if ((mods and 8) != 0) metaState = metaState or KeyEvent.META_META_ON
        
        // Try to map the key code
        val keyCode = mapKeyCode(code, key)
        
        if (keyCode != KeyEvent.KEYCODE_UNKNOWN) {
            val event = KeyEvent(
                eventTime,
                eventTime,
                action,
                keyCode,
                0,
                metaState
            )
            
            activity.runOnUiThread {
                activity.dispatchKeyEvent(event)
            }
        } else {
            // For character keys, try to generate from character
            if (key.length == 1) {
                val charCode = key[0].code
                val events = KeyCharacterMap.load(KeyCharacterMap.VIRTUAL_KEYBOARD)
                    .getEvents(charArrayOf(key[0]))
                
                if (events != null) {
                    activity.runOnUiThread {
                        for (event in events) {
                            activity.dispatchKeyEvent(event)
                        }
                    }
                }
            }
        }
    }

    private fun injectTouch(touches: List<Map<String, Any>>) {
        if (touches.isEmpty()) return
        
        val eventTime = android.os.SystemClock.uptimeMillis()
        
        // For simplicity, handle single touch for now
        val touch = touches[0]
        val x = (touch["x"] as? Number)?.toFloat() ?: 0f
        val y = (touch["y"] as? Number)?.toFloat() ?: 0f
        val id = (touch["id"] as? Number)?.toInt() ?: 0
        val phase = touch["phase"] as? String ?: "move"
        
        val action = when (phase) {
            "began", "down" -> MotionEvent.ACTION_DOWN
            "ended", "up" -> MotionEvent.ACTION_UP
            "moved", "move" -> MotionEvent.ACTION_MOVE
            "cancelled", "cancel" -> MotionEvent.ACTION_CANCEL
            else -> MotionEvent.ACTION_MOVE
        }
        
        val event = MotionEvent.obtain(
            eventTime,
            eventTime,
            action,
            x,
            y,
            0
        )
        
        activity.runOnUiThread {
            activity.dispatchTouchEvent(event)
        }
        
        event.recycle()
    }

    private fun mapKeyCode(sdlCode: Int, key: String): Int {
        // Map SDL key codes to Android key codes
        return when (sdlCode) {
            13 -> KeyEvent.KEYCODE_ENTER
            9 -> KeyEvent.KEYCODE_TAB
            32 -> KeyEvent.KEYCODE_SPACE
            8 -> KeyEvent.KEYCODE_DEL
            27 -> KeyEvent.KEYCODE_ESCAPE
            1073741906 -> KeyEvent.KEYCODE_DPAD_UP
            1073741905 -> KeyEvent.KEYCODE_DPAD_DOWN
            1073741904 -> KeyEvent.KEYCODE_DPAD_LEFT
            1073741903 -> KeyEvent.KEYCODE_DPAD_RIGHT
            1073741898 -> KeyEvent.KEYCODE_MOVE_HOME
            1073741901 -> KeyEvent.KEYCODE_MOVE_END
            1073741899 -> KeyEvent.KEYCODE_PAGE_UP
            1073741900 -> KeyEvent.KEYCODE_PAGE_DOWN
            127 -> KeyEvent.KEYCODE_FORWARD_DEL
            1073741897 -> KeyEvent.KEYCODE_INSERT
            1073742049, 1073742053 -> KeyEvent.KEYCODE_SHIFT_LEFT
            1073742048, 1073742052 -> KeyEvent.KEYCODE_CTRL_LEFT
            1073742050, 1073742054 -> KeyEvent.KEYCODE_ALT_LEFT
            1073742051, 1073742055 -> KeyEvent.KEYCODE_META_LEFT
            else -> {
                // Try to map single character keys
                if (key.length == 1) {
                    val char = key[0].uppercaseChar()
                    when (char) {
                        in 'A'..'Z' -> KeyEvent.KEYCODE_A + (char - 'A')
                        in '0'..'9' -> KeyEvent.KEYCODE_0 + (char - '0')
                        else -> KeyEvent.KEYCODE_UNKNOWN
                    }
                } else {
                    KeyEvent.KEYCODE_UNKNOWN
                }
            }
        }
    }

    fun dispose() {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
