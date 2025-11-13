import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../webrtc/data_channel.dart';
import 'gamepad/gamepad_mappings.dart';
import 'gamepad/windows_gamepad_stub.dart'
    if (dart.library.ffi) 'gamepad/windows_gamepad_impl.dart';

/// Gamepad input controller that normalizes native events into remotecontrol's
/// XInput-style JSON schema.
class GamepadController {
  GamepadController({
    required this.dataChannelManager,
  }) : _logger = Logger();

  static const EventChannel _androidChannel =
      EventChannel('realdesk/hardware_gamepad');

  final DataChannelManager dataChannelManager;
  final Logger _logger;

  StreamSubscription<dynamic>? _eventSubscription;
  WindowsGamepadBridge? _windowsBridge;

  final Map<int, _TrackedDevice> _devices = {};
  final List<int> _freeIndices = [];
  int _nextIndex = 0;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool get _isRunning => _eventSubscription != null;

  /// Start listening for hardware gamepad events.
  void start() {
    if (_isRunning) {
      _logger.w('Gamepad listener already started');
      return;
    }

    if (_isAndroid) {
      _logger.i('Subscribing to Android hardware gamepad stream');
      _eventSubscription = _androidChannel
          .receiveBroadcastStream()
          .listen(
        _handleHardwareEvent,
        onError: (error, stackTrace) {
          _logger.w(
            'Gamepad stream error',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
      return;
    }

    if (_isWindows) {
      _windowsBridge = WindowsGamepadBridge(_logger);
      final bridge = _windowsBridge!;
      _eventSubscription = bridge.events.listen(
        _handleHardwareEvent,
        onError: (error, stackTrace) {
          _logger.w(
            'Windows gamepad bridge error',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
      bridge.start();
      return;
    }

    _logger.i('Gamepad hardware listener available on Android/Windows only');
  }

  /// Stop listening.
  void stop() {
    _eventSubscription?.cancel();
    _eventSubscription = null;

    _windowsBridge?.dispose();
    _windowsBridge = null;

    _clearDevices();
  }

  /// Dispose resources
  void dispose() {
    stop();
  }

  /// Manual update hook (primarily for testing).
  void updateGamepadState({
    required int index,
    required int buttonsMask,
    required double lx,
    required double ly,
    required double rx,
    required double ry,
    required double lt,
    required double rt,
  }) {
    dataChannelManager.sendGamepadState(
      index: index,
      buttonsMask: buttonsMask,
      lx: lx,
      ly: ly,
      rx: rx,
      ry: ry,
      lt: lt,
      rt: rt,
    );
  }

  /// Apply feedback (rumble/LED). Currently best-effort logging.
  void handleFeedback({
    required int index,
    required double largeMotor,
    required double smallMotor,
    required int ledCode,
  }) {
    _logger.i(
      'Received gamepad feedback for index=$index '
      '(large=$largeMotor, small=$smallMotor, led=$ledCode)',
    );
    // TODO: Bridge rumble/LED updates into platform-specific APIs.
  }

  void _handleHardwareEvent(dynamic event) {
    if (event is! Map) {
      return;
    }
    final deviceId = (event['deviceId'] as num?)?.toInt();
    if (deviceId == null) {
      return;
    }
    final kind = event['kind'] as String? ?? 'state';
    if (kind == 'connection') {
      final connected = event['connected'] == true;
      _handleConnectionChange(deviceId, connected);
      return;
    }
    final axes = _toDoubleList(event['axes']);
    final buttons = _toBoolList(event['buttons']);
    _handleState(deviceId, axes, buttons);
  }

  void _handleConnectionChange(int deviceId, bool connected) {
    if (connected) {
      final device = _devices.putIfAbsent(
        deviceId,
        () => _TrackedDevice(_acquireIndex()),
      );
      if (!device.notifiedConnected) {
        _sendConnection(device.index, true);
        device.notifiedConnected = true;
      }
      return;
    }

    final device = _devices.remove(deviceId);
    if (device == null) {
      return;
    }
    if (device.notifiedConnected) {
      _sendConnection(device.index, false);
    }
    _releaseIndex(device.index);
  }

  void _handleState(
    int deviceId,
    List<double> axes,
    List<bool> buttons,
  ) {
    var device = _devices[deviceId];
    if (device == null) {
      device = _TrackedDevice(_acquireIndex());
      _devices[deviceId] = device;
    }
    if (!device.notifiedConnected) {
      _sendConnection(device.index, true);
      device.notifiedConnected = true;
    }

    final reading = _buildReading(axes, buttons);
    if (reading == null) {
      return;
    }
    if (device.lastReading != null &&
        device.lastReading!.roughlyEquals(reading)) {
      return;
    }
    device.lastReading = reading;

    dataChannelManager.sendGamepadState(
      index: device.index,
      buttonsMask: reading.buttonsMask,
      lx: reading.lx,
      ly: reading.ly,
      rx: reading.rx,
      ry: reading.ry,
      lt: reading.lt,
      rt: reading.rt,
    );
  }

  _GamepadReading? _buildReading(
    List<double> axes,
    List<bool> buttons,
  ) {
    final lx = _axisValue(axes, GamepadAxisIndex.lx);
    final ly = -_axisValue(axes, GamepadAxisIndex.ly);
    final rx = _axisValue(axes, GamepadAxisIndex.rx);
    final ry = -_axisValue(axes, GamepadAxisIndex.ry);
    final lt = _triggerValue(axes, GamepadAxisIndex.lt);
    final rt = _triggerValue(axes, GamepadAxisIndex.rt);
    final buttonsMask = _composeButtons(buttons, axes);

    return _GamepadReading(
      buttonsMask: buttonsMask,
      lx: lx,
      ly: ly,
      rx: rx,
      ry: ry,
      lt: lt,
      rt: rt,
    );
  }

  int _composeButtons(List<bool> buttons, List<double> axes) {
    int mask = 0;
    for (final entry in kAndroidButtonIndexToMask.entries) {
      final index = entry.key;
      if (index < buttons.length && buttons[index]) {
        mask |= entry.value;
      }
    }

    final hatX = _axisValue(axes, GamepadAxisIndex.hatX);
    if (hatX <= -0.5) {
      mask |= XUsbButtons.dpadLeft;
    } else if (hatX >= 0.5) {
      mask |= XUsbButtons.dpadRight;
    }

    final hatY = _axisValue(axes, GamepadAxisIndex.hatY);
    if (hatY <= -0.5) {
      mask |= XUsbButtons.dpadUp;
    } else if (hatY >= 0.5) {
      mask |= XUsbButtons.dpadDown;
    }

    return mask;
  }

  void _sendConnection(int index, bool connected) {
    dataChannelManager.sendGamepadConnection(
      index: index,
      connected: connected,
    );
  }

  int _acquireIndex() {
    if (_freeIndices.isNotEmpty) {
      return _freeIndices.removeLast();
    }
    return _nextIndex++;
  }

  void _releaseIndex(int index) {
    if (!_freeIndices.contains(index)) {
      _freeIndices.add(index);
    }
  }

  void _clearDevices() {
    if (_devices.isEmpty) {
      return;
    }
    for (final device in _devices.values) {
      if (device.notifiedConnected) {
        _sendConnection(device.index, false);
      }
      _releaseIndex(device.index);
    }
    _devices.clear();
  }

  List<double> _toDoubleList(dynamic source) {
    if (source is List) {
      return source
          .map((value) => (value as num?)?.toDouble() ?? 0.0)
          .toList(growable: false);
    }
    return const [];
  }

  List<bool> _toBoolList(dynamic source) {
    if (source is List) {
      return source.map((value) => value == true).toList(growable: false);
    }
    return const [];
  }

  double _axisValue(List<double> axes, int index) {
    if (index < 0 || index >= axes.length) {
      return 0.0;
    }
    final value = axes[index];
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }
    if (value > 1.0) {
      return 1.0;
    }
    if (value < -1.0) {
      return -1.0;
    }
    return value;
  }

  double _triggerValue(List<double> axes, int index) {
    final raw = _axisValue(axes, index);
    // Android may report triggers as [-1, 1] or [0, 1]; normalize to [0, 1].
    final normalized = (raw + 1.0) / 2.0;
    if (normalized.isNaN) {
      return 0.0;
    }
    if (normalized > 1.0) {
      return 1.0;
    }
    if (normalized < 0.0) {
      return 0.0;
    }
    return normalized;
  }
}

class _TrackedDevice {
  _TrackedDevice(this.index);

  final int index;
  bool notifiedConnected = false;
  _GamepadReading? lastReading;
}

class _GamepadReading {
  _GamepadReading({
    required this.buttonsMask,
    required this.lx,
    required this.ly,
    required this.rx,
    required this.ry,
    required this.lt,
    required this.rt,
  });

  final int buttonsMask;
  final double lx;
  final double ly;
  final double rx;
  final double ry;
  final double lt;
  final double rt;

  bool roughlyEquals(_GamepadReading other) {
    return buttonsMask == other.buttonsMask &&
        (_almostEqual(lx, other.lx) &&
            _almostEqual(ly, other.ly) &&
            _almostEqual(rx, other.rx) &&
            _almostEqual(ry, other.ry) &&
            _almostEqual(lt, other.lt) &&
            _almostEqual(rt, other.rt));
  }

  bool _almostEqual(double a, double b, [double epsilon = 1e-4]) {
    return (a - b).abs() <= epsilon;
  }
}
