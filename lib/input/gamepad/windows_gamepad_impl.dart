import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'gamepad_mappings.dart';

typedef _XInputGetStateNative = Uint32 Function(
  Uint32 dwUserIndex,
  Pointer<XInputStateStruct>,
);
typedef _XInputGetStateDart = int Function(
  int dwUserIndex,
  Pointer<XInputStateStruct>,
);

/// Windows-specific gamepad polling bridge using XInput.
class WindowsGamepadBridge {
  WindowsGamepadBridge(this._logger)
      : _supported =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.windows,
        _controller = StreamController<Map<String, dynamic>>.broadcast();

  static const int _maxControllers = 4;
  static const int _errorSuccess = 0;

  final Logger _logger;
  final bool _supported;
  final StreamController<Map<String, dynamic>> _controller;

  final List<bool> _connected =
      List<bool>.filled(_maxControllers, false, growable: false);
  final List<int> _lastPacketNumbers =
      List<int>.filled(_maxControllers, -1, growable: false);

  Timer? _pollTimer;
  _XInputGetStateDart? _xinputGetState;
  Pointer<XInputStateStruct>? _statePtr;

  Stream<Map<String, dynamic>> get events => _controller.stream;

  void start() {
    if (!_supported) {
      _logger.d('Windows gamepad bridge disabled (platform not supported)');
      return;
    }
    if (_pollTimer != null) {
      return;
    }
    if (!_ensureLoaded()) {
      _logger.w('Failed to load XInput DLLs; gamepad bridge disabled');
      return;
    }
    _pollTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _poll());
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _controller.close();
    final ptr = _statePtr;
    if (ptr != null) {
      calloc.free(ptr);
      _statePtr = null;
    }
    _xinputGetState = null;
  }

  bool _ensureLoaded() {
    if (_xinputGetState != null) {
      return true;
    }
    const candidates = [
      'xinput1_4.dll',
      'xinput1_3.dll',
      'xinput9_1_0.dll',
    ];
    for (final dll in candidates) {
      try {
        final lib = DynamicLibrary.open(dll);
        final getter = lib.lookupFunction<_XInputGetStateNative,
            _XInputGetStateDart>('XInputGetState');
        _xinputGetState = getter;
        _logger.d('Loaded $dll for Windows gamepad polling');
        return true;
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  void _poll() {
    final getState = _xinputGetState;
    if (getState == null) {
      return;
    }
    final statePtr = _statePtr ??= calloc<XInputStateStruct>();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var slot = 0; slot < _maxControllers; slot++) {
      final result = getState(slot, statePtr);
      if (result == _errorSuccess) {
        _handleConnectedSlot(slot, statePtr.ref, timestamp);
      } else {
        _handleDisconnectedSlot(slot);
      }
    }
  }

  void _handleConnectedSlot(
    int slot,
    XInputStateStruct state,
    int timestamp,
  ) {
    if (!_connected[slot]) {
      _connected[slot] = true;
      _controller.add({
        'kind': 'connection',
        'deviceId': slot,
        'connected': true,
      });
    }
    if (_lastPacketNumbers[slot] == state.dwPacketNumber) {
      return;
    }
    _lastPacketNumbers[slot] = state.dwPacketNumber;
    _controller.add(_serializeState(slot, state.gamepad, timestamp));
  }

  void _handleDisconnectedSlot(int slot) {
    if (!_connected[slot]) {
      return;
    }
    _connected[slot] = false;
    _lastPacketNumbers[slot] = -1;
    _controller.add({
      'kind': 'connection',
      'deviceId': slot,
      'connected': false,
    });
  }

  Map<String, dynamic> _serializeState(
    int slot,
    XInputGamepadStruct gamepad,
    int timestamp,
  ) {
    final axes = List<double>.filled(12, 0.0);
    axes[GamepadAxisIndex.lx] = _normalizeStick(gamepad.sThumbLX);
    axes[GamepadAxisIndex.ly] = _normalizeStick(gamepad.sThumbLY);
    axes[GamepadAxisIndex.rx] = _normalizeStick(gamepad.sThumbRX);
    axes[GamepadAxisIndex.ry] = _normalizeStick(gamepad.sThumbRY);
    axes[GamepadAxisIndex.lt] = gamepad.bLeftTrigger / 255.0;
    axes[GamepadAxisIndex.rt] = gamepad.bRightTrigger / 255.0;

    double hatX = 0.0;
    if ((gamepad.wButtons & XUsbButtons.dpadLeft) != 0) {
      hatX = -1.0;
    } else if ((gamepad.wButtons & XUsbButtons.dpadRight) != 0) {
      hatX = 1.0;
    }
    double hatY = 0.0;
    if ((gamepad.wButtons & XUsbButtons.dpadUp) != 0) {
      hatY = -1.0;
    } else if ((gamepad.wButtons & XUsbButtons.dpadDown) != 0) {
      hatY = 1.0;
    }
    axes[GamepadAxisIndex.hatX] = hatX;
    axes[GamepadAxisIndex.hatY] = hatY;

    final buttons = List<bool>.filled(17, false);
    void setButton(int mask, int index) {
      if (index < buttons.length) {
        buttons[index] = (gamepad.wButtons & mask) != 0;
      }
    }

    setButton(XUsbButtons.a, 0);
    setButton(XUsbButtons.b, 1);
    setButton(XUsbButtons.x, 2);
    setButton(XUsbButtons.y, 3);
    setButton(XUsbButtons.leftShoulder, 4);
    setButton(XUsbButtons.rightShoulder, 5);
    buttons[6] = axes[GamepadAxisIndex.lt] > 0.1;
    buttons[7] = axes[GamepadAxisIndex.rt] > 0.1;
    setButton(XUsbButtons.leftThumb, 8);
    setButton(XUsbButtons.rightThumb, 9);
    setButton(XUsbButtons.start, 10);
    setButton(XUsbButtons.back, 11);
    setButton(XUsbButtons.guide, 12);
    setButton(XUsbButtons.dpadUp, 13);
    setButton(XUsbButtons.dpadDown, 14);
    setButton(XUsbButtons.dpadLeft, 15);
    setButton(XUsbButtons.dpadRight, 16);

    return {
      'kind': 'state',
      'deviceId': slot,
      'timestamp': timestamp,
      'axes': axes,
      'buttons': buttons,
    };
  }

  double _normalizeStick(int value) {
    double normalized;
    if (value >= 0) {
      normalized = value.toDouble() / 32767.0;
    } else {
      normalized = value.toDouble() / 32768.0;
    }
    if (normalized > 1.0) {
      return 1.0;
    }
    if (normalized < -1.0) {
      return -1.0;
    }
    return normalized;
  }
}

@Packed(1)
base class XInputGamepadStruct extends Struct {
  @Uint16()
  external int wButtons;

  @Uint8()
  external int bLeftTrigger;

  @Uint8()
  external int bRightTrigger;

  @Int16()
  external int sThumbLX;

  @Int16()
  external int sThumbLY;

  @Int16()
  external int sThumbRX;

  @Int16()
  external int sThumbRY;
}

@Packed(1)
base class XInputStateStruct extends Struct {
  @Uint32()
  external int dwPacketNumber;

  external XInputGamepadStruct gamepad;
}
