import 'package:flutter/services.dart' as services;
import 'package:logger/logger.dart';

import '../webrtc/data_channel.dart';
import 'key_mapping.dart';
import 'schema/input_messages.dart';

/// Keyboard input controller
class KeyboardController {
  KeyboardController({required this.dataChannelManager}) : _logger = Logger();

  final DataChannelManager dataChannelManager;
  final Logger _logger;

  final Set<services.LogicalKeyboardKey> _pressedKeys = {};

  /// Handle key event
  bool handleKeyEvent(services.KeyEvent event) {
    if (event is services.KeyDownEvent) {
      return _handleKeyDown(event);
    } else if (event is services.KeyUpEvent) {
      return _handleKeyUp(event);
    } else if (event is services.KeyRepeatEvent) {
      return _handleKeyRepeat(event);
    }
    return false;
  }

  bool _handleKeyDown(services.KeyDownEvent event) {
    _pressedKeys.add(event.logicalKey);

    final modifiers = _getModifiers();
    final keyName = KeyMapping.keyNameFor(event.logicalKey);
    final code = KeyMapping.keyCodeFor(event.logicalKey);

    dataChannelManager.sendKeyboard(
      key: keyName,
      down: true,
      code: code,
      meta: {
        'ctrl': modifiers.ctrl,
        'alt': modifiers.alt,
        'shift': modifiers.shift,
        'meta': modifiers.meta,
      },
    );

    _logger.d('Key down: ${event.logicalKey.keyLabel}');
    return true;
  }

  bool _handleKeyUp(services.KeyUpEvent event) {
    _pressedKeys.remove(event.logicalKey);

    final modifiers = _getModifiers();
    final keyName = KeyMapping.keyNameFor(event.logicalKey);
    final code = KeyMapping.keyCodeFor(event.logicalKey);

    dataChannelManager.sendKeyboard(
      key: keyName,
      down: false,
      code: code,
      meta: {
        'ctrl': modifiers.ctrl,
        'alt': modifiers.alt,
        'shift': modifiers.shift,
        'meta': modifiers.meta,
      },
    );

    _logger.d('Key up: ${event.logicalKey.keyLabel}');
    return true;
  }

  bool _handleKeyRepeat(services.KeyRepeatEvent event) {
    // For repeat events, we can choose to ignore or send as down events
    return true;
  }

  /// Get current keyboard modifiers
  KeyboardModifiers _getModifiers() {
    return KeyboardModifiers(
      ctrl: _pressedKeys.contains(services.LogicalKeyboardKey.controlLeft) ||
          _pressedKeys.contains(services.LogicalKeyboardKey.controlRight),
      alt: _pressedKeys.contains(services.LogicalKeyboardKey.altLeft) ||
          _pressedKeys.contains(services.LogicalKeyboardKey.altRight),
      shift: _pressedKeys.contains(services.LogicalKeyboardKey.shiftLeft) ||
          _pressedKeys.contains(services.LogicalKeyboardKey.shiftRight),
      meta: _pressedKeys.contains(services.LogicalKeyboardKey.metaLeft) ||
          _pressedKeys.contains(services.LogicalKeyboardKey.metaRight),
    );
  }

  /// Reset all pressed keys
  void reset() {
    _pressedKeys.clear();
  }

  /// Simulate a key event from virtual keyboard
  void simulateKey(services.LogicalKeyboardKey key, bool down) {
    if (down) {
      _pressedKeys.add(key);
    } else {
      _pressedKeys.remove(key);
    }

    final modifiers = _getModifiers();
    final keyName = KeyMapping.keyNameFor(key);
    final code = KeyMapping.keyCodeFor(key);

    dataChannelManager.sendKeyboard(
      key: keyName,
      down: down,
      code: code,
      meta: {
        'ctrl': modifiers.ctrl,
        'alt': modifiers.alt,
        'shift': modifiers.shift,
        'meta': modifiers.meta,
      },
    );
  }
}
