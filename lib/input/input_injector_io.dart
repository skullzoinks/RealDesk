import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import 'uiohook_ffi.dart';

/// Input injector for receiving and simulating remote control events
/// This handles incoming mouse, keyboard, and touch events from remote controller
class InputInjector {
  InputInjector() : _logger = Logger();

  final Logger _logger;
  static const MethodChannel _channel =
      MethodChannel('realdesk/input_injection');

  // Track whether we're using FFI (desktop) or MethodChannel (Android)
  bool _useFFI = false;
  int _lastButtons = 0; // Track previous button state for FFI

  /// Initialize the input injector
  Future<bool> initialize() async {
    // Use FFI for desktop platforms, MethodChannel for Android
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      try {
        // Initialize FFI bindings
        UiohookBindings.instance;
        _useFFI = true;
        _logger.i('Input injector initialized with FFI');
        return true;
      } catch (e) {
        _logger
            .e('Failed to initialize FFI, falling back to MethodChannel: $e');
        _useFFI = false;
      }
    }

    // Fallback to MethodChannel for Android or if FFI fails
    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      _logger.i('Input injector initialized with MethodChannel: $result');
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
    if (_useFFI) {
      try {
        // Convert normalized coordinates to screen coordinates
        final screenX = (x * displayW).round();
        final screenY = (y * displayH).round();

        // Move mouse to position
        UiohookEventHelper.postMouseMoveEvent(
            screenX, screenY, _buttonsToMask(buttons));

        // Handle button state changes
        final buttonChanges = buttons ^ _lastButtons;
        if (buttonChanges != 0) {
          for (int i = 0; i < 5; i++) {
            final buttonMask = 1 << i;
            if (buttonChanges & buttonMask != 0) {
              final isPressed = buttons & buttonMask != 0;
              final eventType =
                  isPressed ? EVENT_MOUSE_PRESSED : EVENT_MOUSE_RELEASED;
              final button =
                  i + 1; // Convert to MOUSE_BUTTON1, MOUSE_BUTTON2, etc.
              UiohookEventHelper.postMouseButtonEvent(
                eventType,
                button,
                screenX,
                screenY,
                1,
                _buttonsToMask(buttons),
              );
            }
          }
        }
        _lastButtons = buttons;

        _logger.d(
            'Injected mouse abs (FFI): ($screenX, $screenY) buttons=$buttons');
      } catch (e) {
        _logger.e('Failed to inject mouse abs (FFI): $e');
      }
    } else {
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
  }

  /// Inject mouse relative movement event
  Future<void> injectMouseRelative({
    required double dx,
    required double dy,
    required int buttons,
  }) async {
    if (_useFFI) {
      try {
        // For relative movement, we need to get current position and add delta
        // Note: libuiohook doesn't support relative moves directly, use absolute
        _logger.w('Relative mouse movement not fully supported with FFI');
      } catch (e) {
        _logger.e('Failed to inject mouse rel (FFI): $e');
      }
    } else {
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
  }

  /// Inject mouse wheel/scroll event
  Future<void> injectMouseWheel({
    required double dx,
    required double dy,
  }) async {
    if (_useFFI) {
      try {
        // Vertical scroll
        if (dy != 0) {
          final rotation =
              (dy * 120).round(); // Convert to wheel rotation units
          UiohookEventHelper.postMouseWheelEvent(
            0,
            0,
            rotation,
            WHEEL_VERTICAL_DIRECTION,
            0,
          );
        }
        // Horizontal scroll
        if (dx != 0) {
          final rotation = (dx * 120).round();
          UiohookEventHelper.postMouseWheelEvent(
            0,
            0,
            rotation,
            WHEEL_HORIZONTAL_DIRECTION,
            0,
          );
        }
        _logger.d('Injected wheel (FFI): ($dx, $dy)');
      } catch (e) {
        _logger.e('Failed to inject wheel (FFI): $e');
      }
    } else {
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
  }

  /// Inject keyboard event
  Future<void> injectKeyboard({
    required String key,
    required int code,
    required bool down,
    required int mods,
  }) async {
    if (_useFFI) {
      try {
        final vcCode = sdlToUiohookKeycode(code);
        if (vcCode != VC_UNDEFINED) {
          final eventType = down ? EVENT_KEY_PRESSED : EVENT_KEY_RELEASED;
          final mask = _modsToMask(mods);
          UiohookEventHelper.postKeyboardEvent(eventType, vcCode, mask);
          _logger.d(
              'Injected keyboard (FFI): key=$key vc=$vcCode down=$down mods=$mods');
        } else {
          _logger.w('Unsupported key code: $code');
        }
      } catch (e) {
        _logger.e('Failed to inject keyboard (FFI): $e');
      }
    } else {
      try {
        await _channel.invokeMethod('injectKeyboard', {
          'key': key,
          'code': code,
          'down': down,
          'mods': mods,
        });
        _logger
            .d('Injected keyboard: key=$key code=$code down=$down mods=$mods');
      } catch (e) {
        _logger.e('Failed to inject keyboard: $e');
      }
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

  // Helper methods for FFI
  int _buttonsToMask(int buttons) {
    int mask = 0;
    if (buttons & 0x01 != 0) mask |= MASK_BUTTON1;
    if (buttons & 0x02 != 0) mask |= MASK_BUTTON2;
    if (buttons & 0x04 != 0) mask |= MASK_BUTTON3;
    if (buttons & 0x08 != 0) mask |= MASK_BUTTON4;
    if (buttons & 0x10 != 0) mask |= MASK_BUTTON5;
    return mask;
  }

  int _modsToMask(int mods) {
    int mask = 0;
    if (mods & 0x0001 != 0) mask |= MASK_SHIFT;
    if (mods & 0x0002 != 0) mask |= MASK_CTRL;
    if (mods & 0x0004 != 0) mask |= MASK_ALT;
    if (mods & 0x0008 != 0) mask |= MASK_META;
    return mask;
  }
}
