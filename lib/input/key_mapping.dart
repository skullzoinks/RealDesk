import 'package:flutter/services.dart';

/// Utility for converting Flutter's [LogicalKeyboardKey]s into the SDL-style
/// key codes used by the RealDesk/remotecontrol protocol.
class KeyMapping {
  static const int _sdlScancodeMask = 0x40000000;

  /// SDL key codes that map directly to ASCII values.
  static final Map<int, int> _directKeyCodes = Map.unmodifiable({
    LogicalKeyboardKey.enter.keyId: 13,
    LogicalKeyboardKey.tab.keyId: 9,
    LogicalKeyboardKey.space.keyId: 32,
    LogicalKeyboardKey.backspace.keyId: 8,
    LogicalKeyboardKey.escape.keyId: 27,
    LogicalKeyboardKey.delete.keyId: 127,
    // Punctuation keys
    LogicalKeyboardKey.comma.keyId: 44, // ,
    LogicalKeyboardKey.period.keyId: 46, // .
    LogicalKeyboardKey.slash.keyId: 47, // /
    LogicalKeyboardKey.semicolon.keyId: 59, // ;
    LogicalKeyboardKey.minus.keyId: 45, // -
    LogicalKeyboardKey.equal.keyId: 61, // =
    LogicalKeyboardKey.bracketLeft.keyId: 91, // [
    LogicalKeyboardKey.bracketRight.keyId: 93, // ]
    LogicalKeyboardKey.backslash.keyId: 92, // \
    LogicalKeyboardKey.backquote.keyId: 96, // `
    // Apostrophe/quote key uses the unshifted SDL key code (SDLK_APOSTROPHE)
    LogicalKeyboardKey.quote.keyId: 39,
    LogicalKeyboardKey.quoteSingle.keyId: 39,
  });

  /// SDL scancode-based keys that have no ASCII equivalent.
  static final Map<int, int> _scancodeKeyCodes = Map.unmodifiable({
    // Navigation
    LogicalKeyboardKey.insert.keyId: 73,
    LogicalKeyboardKey.home.keyId: 74,
    LogicalKeyboardKey.pageUp.keyId: 75,
    LogicalKeyboardKey.end.keyId: 77,
    LogicalKeyboardKey.pageDown.keyId: 78,
    LogicalKeyboardKey.arrowRight.keyId: 79,
    LogicalKeyboardKey.arrowLeft.keyId: 80,
    LogicalKeyboardKey.arrowDown.keyId: 81,
    LogicalKeyboardKey.arrowUp.keyId: 82,
    // Locks / system
    LogicalKeyboardKey.capsLock.keyId: 57,
    LogicalKeyboardKey.printScreen.keyId: 70,
    LogicalKeyboardKey.scrollLock.keyId: 71,
    LogicalKeyboardKey.pause.keyId: 72,
    LogicalKeyboardKey.numLock.keyId: 83,
    LogicalKeyboardKey.contextMenu.keyId: 101,
    // Function keys
    LogicalKeyboardKey.f1.keyId: 58,
    LogicalKeyboardKey.f2.keyId: 59,
    LogicalKeyboardKey.f3.keyId: 60,
    LogicalKeyboardKey.f4.keyId: 61,
    LogicalKeyboardKey.f5.keyId: 62,
    LogicalKeyboardKey.f6.keyId: 63,
    LogicalKeyboardKey.f7.keyId: 64,
    LogicalKeyboardKey.f8.keyId: 65,
    LogicalKeyboardKey.f9.keyId: 66,
    LogicalKeyboardKey.f10.keyId: 67,
    LogicalKeyboardKey.f11.keyId: 68,
    LogicalKeyboardKey.f12.keyId: 69,
    LogicalKeyboardKey.f13.keyId: 104,
    LogicalKeyboardKey.f14.keyId: 105,
    LogicalKeyboardKey.f15.keyId: 106,
    LogicalKeyboardKey.f16.keyId: 107,
    LogicalKeyboardKey.f17.keyId: 108,
    LogicalKeyboardKey.f18.keyId: 109,
    LogicalKeyboardKey.f19.keyId: 110,
    LogicalKeyboardKey.f20.keyId: 111,
    LogicalKeyboardKey.f21.keyId: 112,
    LogicalKeyboardKey.f22.keyId: 113,
    LogicalKeyboardKey.f23.keyId: 114,
    LogicalKeyboardKey.f24.keyId: 115,
    // Modifiers
    LogicalKeyboardKey.controlLeft.keyId: 224,
    LogicalKeyboardKey.shiftLeft.keyId: 225,
    LogicalKeyboardKey.altLeft.keyId: 226,
    LogicalKeyboardKey.metaLeft.keyId: 227,
    LogicalKeyboardKey.controlRight.keyId: 228,
    LogicalKeyboardKey.shiftRight.keyId: 229,
    LogicalKeyboardKey.altRight.keyId: 230,
    LogicalKeyboardKey.metaRight.keyId: 231,
    // Numeric keypad
    LogicalKeyboardKey.numpadDivide.keyId: 84,
    LogicalKeyboardKey.numpadMultiply.keyId: 85,
    LogicalKeyboardKey.numpadSubtract.keyId: 86,
    LogicalKeyboardKey.numpadAdd.keyId: 87,
    LogicalKeyboardKey.numpadEnter.keyId: 88,
    LogicalKeyboardKey.numpad1.keyId: 89,
    LogicalKeyboardKey.numpad2.keyId: 90,
    LogicalKeyboardKey.numpad3.keyId: 91,
    LogicalKeyboardKey.numpad4.keyId: 92,
    LogicalKeyboardKey.numpad5.keyId: 93,
    LogicalKeyboardKey.numpad6.keyId: 94,
    LogicalKeyboardKey.numpad7.keyId: 95,
    LogicalKeyboardKey.numpad8.keyId: 96,
    LogicalKeyboardKey.numpad9.keyId: 97,
    LogicalKeyboardKey.numpad0.keyId: 98,
    LogicalKeyboardKey.numpadDecimal.keyId: 99,
    LogicalKeyboardKey.numpadEqual.keyId: 103,
    LogicalKeyboardKey.numpadComma.keyId: 133,
  });

  /// Returns the SDL key code for the provided [logicalKey].
  static int keyCodeFor(LogicalKeyboardKey logicalKey) {
    final direct = _directKeyCodes[logicalKey.keyId];
    if (direct != null) {
      return direct;
    }

    final scancode = _scancodeKeyCodes[logicalKey.keyId];
    if (scancode != null) {
      return _encodeScancode(scancode);
    }

    final ascii = _asciiFromLogicalKey(logicalKey);
    if (ascii != null) {
      return ascii;
    }

    return 0;
  }

  /// Returns a stable, human-readable identifier for the provided [logicalKey].
  static String keyNameFor(LogicalKeyboardKey logicalKey) {
    final label = logicalKey.keyLabel;
    if (label.isNotEmpty) {
      return label;
    }
    final debugName = logicalKey.debugName;
    if (debugName != null && debugName.isNotEmpty) {
      return debugName;
    }
    // Fallback to a unique identifier so the receiver can still log something.
    return 'Key_${logicalKey.keyId.toRadixString(16)}';
  }

  static int _encodeScancode(int scancode) =>
      _sdlScancodeMask | (scancode & 0x7FFFFFFF);

  static int? _asciiFromLogicalKey(LogicalKeyboardKey logicalKey) {
    final label = logicalKey.keyLabel;
    if (label.length == 1) {
      final normalized = label.toLowerCase();
      final code = normalized.codeUnitAt(0);
      if (code >= 32 && code <= 126) {
        return code;
      }
    }

    final debugName = logicalKey.debugName ?? '';
    if (debugName.startsWith('Key ') && debugName.length >= 5) {
      final letter = debugName.substring(4).toLowerCase();
      if (letter.length == 1) {
        final code = letter.codeUnitAt(0);
        if (_isAsciiLetter(code)) {
          return code;
        }
      }
    }
    if (debugName.startsWith('Digit ') && debugName.length >= 7) {
      final digit = debugName.substring(6);
      if (digit.length == 1) {
        final code = digit.codeUnitAt(0);
        if (_isAsciiDigit(code)) {
          return code;
        }
      }
    }
    // if (debugName.startsWith('Numpad ') && debugName.length >= 8) {
    //   final value = debugName.substring(7);
    //   if (value.length == 1) {
    //     final code = value.codeUnitAt(0);
    //     if (_isAsciiDigit(code)) {
    //       return code;
    //     }
    //   }
    // }
    if (debugName.startsWith('Digit ') && debugName.length >= 7) {
      final digit = debugName.substring(6);
      if (digit.length == 1) {
        final code = digit.codeUnitAt(0);
        if (_isAsciiDigit(code)) {
          return code;
        }
      }
    }

    return null;
  }

  static bool _isAsciiLetter(int code) =>
      (code >= 97 && code <= 122) || (code >= 65 && code <= 90);

  static bool _isAsciiDigit(int code) => code >= 48 && code <= 57;
}
