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
import com.google.protobuf.InvalidProtocolBufferException
import remote.proto.RemoteInputProto

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
            "injectInputMessage" -> {
                // New method that accepts both JSON map or binary protobuf bytes
                val data = call.argument<ByteArray>("data")
                val isProtobuf = call.argument<Boolean>("isProtobuf") ?: false
                
                if (data != null && isProtobuf) {
                    injectProtobufMessage(data)
                } else {
                    // Fallback to individual methods for JSON
                    result.notImplemented()
                }
                result.success(null)
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

    private fun injectProtobufMessage(data: ByteArray) {
        try {
            val envelope = RemoteInputProto.Envelope.parseFrom(data)
            
            when (envelope.payloadCase) {
                RemoteInputProto.Envelope.PayloadCase.KEYBOARD -> {
                    val kb = envelope.keyboard
                    injectKeyboard(kb.key, kb.code, kb.down, kb.mods)
                }
                RemoteInputProto.Envelope.PayloadCase.MOUSEABS -> {
                    val m = envelope.mouseAbs
                    injectMouseAbsolute(
                        m.x.toDouble(), 
                        m.y.toDouble(),
                        m.displayW,
                        m.displayH,
                        m.btns.bits
                    )
                }
                RemoteInputProto.Envelope.PayloadCase.MOUSEREL -> {
                    val m = envelope.mouseRel
                    injectMouseRelative(
                        m.dx.toDouble(),
                        m.dy.toDouble(),
                        m.btns.bits
                    )
                }
                RemoteInputProto.Envelope.PayloadCase.MOUSEWHEEL -> {
                    val m = envelope.mouseWheel
                    injectMouseWheel(m.dx.toDouble(), m.dy.toDouble())
                }
                else -> {
                    android.util.Log.d(TAG, "Unhandled protobuf message type: ${envelope.payloadCase}")
                }
            }
        } catch (e: InvalidProtocolBufferException) {
            android.util.Log.e(TAG, "Failed to parse protobuf message", e)
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
            127 -> KeyEvent.KEYCODE_FORWARD_DEL
            1073741881 -> KeyEvent.KEYCODE_CAPS_LOCK
            1073741882 -> KeyEvent.KEYCODE_F1
            1073741883 -> KeyEvent.KEYCODE_F2
            1073741884 -> KeyEvent.KEYCODE_F3
            1073741885 -> KeyEvent.KEYCODE_F4
            1073741886 -> KeyEvent.KEYCODE_F5
            1073741887 -> KeyEvent.KEYCODE_F6
            1073741888 -> KeyEvent.KEYCODE_F7
            1073741889 -> KeyEvent.KEYCODE_F8
            1073741890 -> KeyEvent.KEYCODE_F9
            1073741891 -> KeyEvent.KEYCODE_F10
            1073741892 -> KeyEvent.KEYCODE_F11
            1073741893 -> KeyEvent.KEYCODE_F12
            1073741894 -> KeyEvent.KEYCODE_SYSRQ
            1073741895 -> KeyEvent.KEYCODE_SCROLL_LOCK
            1073741896 -> KeyEvent.KEYCODE_BREAK
            1073741897 -> KeyEvent.KEYCODE_INSERT
            1073741898 -> KeyEvent.KEYCODE_MOVE_HOME
            1073741899 -> KeyEvent.KEYCODE_PAGE_UP
            1073741900 -> KeyEvent.KEYCODE_PAGE_DOWN
            1073741901 -> KeyEvent.KEYCODE_MOVE_END
            1073741903 -> KeyEvent.KEYCODE_DPAD_RIGHT
            1073741904 -> KeyEvent.KEYCODE_DPAD_LEFT
            1073741905 -> KeyEvent.KEYCODE_DPAD_DOWN
            1073741906 -> KeyEvent.KEYCODE_DPAD_UP
            1073741907 -> KeyEvent.KEYCODE_NUM_LOCK
            1073741908 -> KeyEvent.KEYCODE_NUMPAD_DIVIDE
            1073741909 -> KeyEvent.KEYCODE_NUMPAD_MULTIPLY
            1073741910 -> KeyEvent.KEYCODE_NUMPAD_SUBTRACT
            1073741911 -> KeyEvent.KEYCODE_NUMPAD_ADD
            1073741912 -> KeyEvent.KEYCODE_NUMPAD_ENTER
            1073741913 -> KeyEvent.KEYCODE_NUMPAD_1
            1073741914 -> KeyEvent.KEYCODE_NUMPAD_2
            1073741915 -> KeyEvent.KEYCODE_NUMPAD_3
            1073741916 -> KeyEvent.KEYCODE_NUMPAD_4
            1073741917 -> KeyEvent.KEYCODE_NUMPAD_5
            1073741918 -> KeyEvent.KEYCODE_NUMPAD_6
            1073741919 -> KeyEvent.KEYCODE_NUMPAD_7
            1073741920 -> KeyEvent.KEYCODE_NUMPAD_8
            1073741921 -> KeyEvent.KEYCODE_NUMPAD_9
            1073741922 -> KeyEvent.KEYCODE_NUMPAD_0
            1073741923 -> KeyEvent.KEYCODE_NUMPAD_DOT
            1073741927 -> KeyEvent.KEYCODE_NUMPAD_EQUALS
            1073741957 -> KeyEvent.KEYCODE_NUMPAD_COMMA
            1073742048 -> KeyEvent.KEYCODE_CTRL_LEFT
            1073742052 -> KeyEvent.KEYCODE_CTRL_RIGHT
            1073742049 -> KeyEvent.KEYCODE_SHIFT_LEFT
            1073742053 -> KeyEvent.KEYCODE_SHIFT_RIGHT
            1073742050 -> KeyEvent.KEYCODE_ALT_LEFT
            1073742054 -> KeyEvent.KEYCODE_ALT_RIGHT
            1073742051 -> KeyEvent.KEYCODE_META_LEFT
            1073742055 -> KeyEvent.KEYCODE_META_RIGHT
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
