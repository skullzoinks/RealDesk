import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../webrtc/data_channel.dart';

/// Gamepad input controller that bridges native controller events into the
/// WebRTC data channel.
class GamepadController {
  GamepadController({
    required this.dataChannelManager,
  }) : _logger = Logger();

  static const EventChannel _eventChannel =
      EventChannel('realdesk/hardware_gamepad');

  final DataChannelManager dataChannelManager;
  final Logger _logger;

  StreamSubscription<dynamic>? _nativeSubscription;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Start listening for hardware gamepad events.
  void start() {
    if (_nativeSubscription != null) {
      _logger.w('Gamepad listener already started');
      return;
    }

    if (!_isAndroid) {
      _logger.i('Gamepad hardware listener only available on Android');
      return;
    }

    _logger.i('Subscribing to Android hardware gamepad stream');
    _nativeSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleNativeEvent, onError: (error, stackTrace) {
      _logger.w('Gamepad stream error: $error\n$stackTrace');
    });
  }

  /// Stop listening.
  void stop() {
    _nativeSubscription?.cancel();
    _nativeSubscription = null;
  }

  void _handleNativeEvent(dynamic event) {
    if (event is! Map) {
      return;
    }

    final deviceId = (event['deviceId'] as num?)?.toInt() ?? 0;
    final timestamp = (event['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final axes = _toDoubleList(event['axes']);
    final buttons = _toBoolList(event['buttons']);

    dataChannelManager.sendGamepadEvent(
      gamepadEvent: {
        'index': deviceId,
        'axes': axes,
        'buttons': buttons,
        'timestamp': timestamp,
      },
    );
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

  /// Manual update hook (primarily for testing).
  void updateGamepadState({
    required int index,
    required List<double> axes,
    required List<bool> buttons,
  }) {
    dataChannelManager.sendGamepadEvent(
      gamepadEvent: {
        'index': index,
        'axes': axes,
        'buttons': buttons,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}
