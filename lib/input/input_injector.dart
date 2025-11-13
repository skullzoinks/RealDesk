import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Input injector for receiving and simulating remote control events
/// This handles incoming mouse, keyboard, and touch events from remote controller
class InputInjector {
  InputInjector() : _logger = Logger();

  final Logger _logger;
  static const MethodChannel _channel =
      MethodChannel('realdesk/input_injection');

  /// Initialize the input injector
  Future<bool> initialize() async {
    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      _logger.i('Input injector initialized: $result');
      return result ?? false;
    } catch (e) {
      _logger.e('Failed to initialize input injector: $e');
      return false;
    }
  }

  /// Inject mouse absolute position event
  Future<void> injectMouseAbsolute({
    required double x,
    required double y,
    required int displayW,
    required int displayH,
    required int buttons,
  }) async {
    try {
      await _channel.invokeMethod('injectMouseAbs', {
        'x': x,
        'y': y,
        'displayW': displayW,
        'displayH': displayH,
        'buttons': buttons,
      });
      _logger.d('Injected mouse abs: ($x, $y) buttons=$buttons');
    } catch (e) {
      _logger.e('Failed to inject mouse abs: $e');
    }
  }

  /// Inject mouse relative movement event
  Future<void> injectMouseRelative({
    required double dx,
    required double dy,
    required int buttons,
  }) async {
    try {
      await _channel.invokeMethod('injectMouseRel', {
        'dx': dx,
        'dy': dy,
        'buttons': buttons,
      });
      _logger.d('Injected mouse rel: ($dx, $dy) buttons=$buttons');
    } catch (e) {
      _logger.e('Failed to inject mouse rel: $e');
    }
  }

  /// Inject mouse wheel/scroll event
  Future<void> injectMouseWheel({
    required double dx,
    required double dy,
  }) async {
    try {
      await _channel.invokeMethod('injectWheel', {
        'dx': dx,
        'dy': dy,
      });
      _logger.d('Injected wheel: ($dx, $dy)');
    } catch (e) {
      _logger.e('Failed to inject wheel: $e');
    }
  }

  /// Inject keyboard event
  Future<void> injectKeyboard({
    required String key,
    required int code,
    required bool down,
    required int mods,
  }) async {
    try {
      await _channel.invokeMethod('injectKeyboard', {
        'key': key,
        'code': code,
        'down': down,
        'mods': mods,
      });
      _logger.d('Injected keyboard: key=$key code=$code down=$down mods=$mods');
    } catch (e) {
      _logger.e('Failed to inject keyboard: $e');
    }
  }

  /// Inject touch event
  Future<void> injectTouch({
    required List<Map<String, dynamic>> touches,
  }) async {
    try {
      await _channel.invokeMethod('injectTouch', {
        'touches': touches,
      });
      _logger.d('Injected touch: ${touches.length} touch points');
    } catch (e) {
      _logger.e('Failed to inject touch: $e');
    }
  }

  /// Cleanup resources
  void dispose() {
    _logger.i('Input injector disposed');
  }
}
