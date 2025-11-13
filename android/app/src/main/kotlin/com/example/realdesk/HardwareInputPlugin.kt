package com.example.realdesk

import android.app.Activity
import android.content.Context
import android.hardware.input.InputManager
import android.os.Handler
import android.os.Looper
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

class HardwareInputPlugin(private val activity: Activity) :
    EventChannel.StreamHandler,
    InputManager.InputDeviceListener {

    companion object {
        private const val CHANNEL = "realdesk/hardware_gamepad"

        private val AXIS_ORDER = intArrayOf(
            MotionEvent.AXIS_X,
            MotionEvent.AXIS_Y,
            MotionEvent.AXIS_Z,
            MotionEvent.AXIS_RX,
            MotionEvent.AXIS_RY,
            MotionEvent.AXIS_RZ,
            MotionEvent.AXIS_LTRIGGER,
            MotionEvent.AXIS_RTRIGGER,
            MotionEvent.AXIS_BRAKE,
            MotionEvent.AXIS_GAS,
            MotionEvent.AXIS_HAT_X,
            MotionEvent.AXIS_HAT_Y,
        )

        private val BUTTON_ORDER = intArrayOf(
            KeyEvent.KEYCODE_BUTTON_A,
            KeyEvent.KEYCODE_BUTTON_B,
            KeyEvent.KEYCODE_BUTTON_X,
            KeyEvent.KEYCODE_BUTTON_Y,
            KeyEvent.KEYCODE_BUTTON_L1,
            KeyEvent.KEYCODE_BUTTON_R1,
            KeyEvent.KEYCODE_BUTTON_L2,
            KeyEvent.KEYCODE_BUTTON_R2,
            KeyEvent.KEYCODE_BUTTON_THUMBL,
            KeyEvent.KEYCODE_BUTTON_THUMBR,
            KeyEvent.KEYCODE_BUTTON_START,
            KeyEvent.KEYCODE_BUTTON_SELECT,
            KeyEvent.KEYCODE_BUTTON_MODE,
            KeyEvent.KEYCODE_DPAD_UP,
            KeyEvent.KEYCODE_DPAD_DOWN,
            KeyEvent.KEYCODE_DPAD_LEFT,
            KeyEvent.KEYCODE_DPAD_RIGHT,
        )
    }

    private val inputManager =
        activity.getSystemService(Context.INPUT_SERVICE) as InputManager
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var isListening = false

    private data class GamepadState(
        val axes: FloatArray = FloatArray(AXIS_ORDER.size),
        val buttons: BooleanArray = BooleanArray(BUTTON_ORDER.size),
    )

    private val states = mutableMapOf<Int, GamepadState>()

    fun startListening(messenger: BinaryMessenger) {
        EventChannel(messenger, CHANNEL).setStreamHandler(this)
    }

    fun dispose() {
        if (isListening) {
            inputManager.unregisterInputDeviceListener(this)
            isListening = false
        }
        states.clear()
        eventSink = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        if (!isListening) {
            inputManager.registerInputDeviceListener(this, handler)
            isListening = true
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        if (isListening) {
            inputManager.unregisterInputDeviceListener(this)
            isListening = false
        }
    }

    fun handleGenericMotion(event: MotionEvent): Boolean {
        val sink = eventSink ?: return false
        if (!isGamepadSource(event.source)) {
            return false
        }
        val action = event.actionMasked
        if (action != MotionEvent.ACTION_MOVE &&
            action != MotionEvent.ACTION_HOVER_MOVE &&
            action != MotionEvent.ACTION_SCROLL
        ) {
            return false
        }

        val deviceId = event.deviceId
        val state = states.getOrPut(deviceId) { GamepadState() }
        AXIS_ORDER.forEachIndexed { index, axis ->
            state.axes[index] = event.getAxisValue(axis)
        }
        emitState(sink, deviceId, event.eventTime)
        return true
    }

    fun handleKeyEvent(event: KeyEvent): Boolean {
        val sink = eventSink ?: return false
        if (!isGamepadSource(event.source) || !isGamepadButton(event.keyCode)) {
            return false
        }
        val buttonIndex = BUTTON_ORDER.indexOf(event.keyCode)
        if (buttonIndex == -1) {
            return false
        }

        val deviceId = event.deviceId
        val state = states.getOrPut(deviceId) { GamepadState() }
        state.buttons[buttonIndex] = event.action != KeyEvent.ACTION_UP
        emitState(sink, deviceId, event.eventTime)
        return true
    }

    private fun emitState(
        sink: EventChannel.EventSink,
        deviceId: Int,
        timestamp: Long,
    ) {
        val state = states[deviceId] ?: return
        val axes = ArrayList<Double>(state.axes.size)
        state.axes.mapTo(axes) { it.toDouble() }
        val buttons = ArrayList<Boolean>(state.buttons.size)
        state.buttons.mapTo(buttons) { it }
        val payload = hashMapOf<String, Any>(
            "deviceId" to deviceId,
            "timestamp" to timestamp,
            "axes" to axes,
            "buttons" to buttons,
        )
        sink.success(payload)
    }

    private fun isGamepadSource(source: Int): Boolean {
        return source and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK ||
            source and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD
    }

    override fun onInputDeviceAdded(deviceId: Int) {
        if (isGamepadDevice(deviceId)) {
            states[deviceId] = GamepadState()
        }
    }

    override fun onInputDeviceRemoved(deviceId: Int) {
        states.remove(deviceId)
    }

    override fun onInputDeviceChanged(deviceId: Int) {
        if (isGamepadDevice(deviceId)) {
            states[deviceId] = GamepadState()
        }
    }

    private fun isGamepadDevice(deviceId: Int): Boolean {
        val device = inputManager.getInputDevice(deviceId) ?: return false
        return isGamepadSource(device.sources)
    }

    private fun isGamepadButton(keyCode: Int): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_BUTTON_A,
            KeyEvent.KEYCODE_BUTTON_B,
            KeyEvent.KEYCODE_BUTTON_X,
            KeyEvent.KEYCODE_BUTTON_Y,
            KeyEvent.KEYCODE_BUTTON_L1,
            KeyEvent.KEYCODE_BUTTON_R1,
            KeyEvent.KEYCODE_BUTTON_L2,
            KeyEvent.KEYCODE_BUTTON_R2,
            KeyEvent.KEYCODE_BUTTON_THUMBL,
            KeyEvent.KEYCODE_BUTTON_THUMBR,
            KeyEvent.KEYCODE_BUTTON_START,
            KeyEvent.KEYCODE_BUTTON_SELECT,
            KeyEvent.KEYCODE_BUTTON_MODE,
            KeyEvent.KEYCODE_DPAD_UP,
            KeyEvent.KEYCODE_DPAD_DOWN,
            KeyEvent.KEYCODE_DPAD_LEFT,
            KeyEvent.KEYCODE_DPAD_RIGHT -> true
            else -> false
        }
    }
}
