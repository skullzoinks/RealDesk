import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:realdesk/input/key_mapping.dart';

void main() {
  group('KeyMapping', () {
    test('maps letter keys to ASCII SDL codes', () {
      expect(
        KeyMapping.keyCodeFor(LogicalKeyboardKey.keyA),
        equals('a'.codeUnitAt(0)),
      );
    });

    test('maps arrow keys to SDL scancode values', () {
      expect(
        KeyMapping.keyCodeFor(LogicalKeyboardKey.arrowUp),
        equals(1073741906),
      );
    });

    test('maps function keys to SDL scancode values', () {
      expect(
        KeyMapping.keyCodeFor(LogicalKeyboardKey.f5),
        equals(1073741886),
      );
    });

    test('maps numpad digits to SDL KP codes', () {
      expect(
        KeyMapping.keyCodeFor(LogicalKeyboardKey.numpad7),
        equals(1073741919),
      );
    });

    test('provides stable key names from debugName', () {
      expect(
        KeyMapping.keyNameFor(LogicalKeyboardKey.f5),
        equals('F5'),
      );
    });

    test('prefers printable labels for ASCII keys', () {
      expect(
        KeyMapping.keyNameFor(LogicalKeyboardKey.quote),
        equals('"'),
      );
      expect(
        KeyMapping.keyNameFor(LogicalKeyboardKey.quoteSingle),
        equals("'"),
      );
      expect(
        KeyMapping.keyNameFor(LogicalKeyboardKey.digit1),
        equals('1'),
      );
    });

    test('maps apostrophe key to SDL apostrophe code', () {
      expect(
        KeyMapping.keyCodeFor(LogicalKeyboardKey.quote),
        equals(39),
      );
      expect(
        KeyMapping.keyCodeFor(LogicalKeyboardKey.quoteSingle),
        equals(39),
      );
    });
  });
}
