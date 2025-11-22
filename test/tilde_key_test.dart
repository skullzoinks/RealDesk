import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realdesk/input/key_mapping.dart';

void main() {
  group('Tilde (~) Key Support', () {
    test('backquote key maps to correct ASCII code', () {
      // The ` key should map to ASCII 96
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.backquote), 96);
    });

    test('tilde is produced via Shift + backquote', () {
      // In the keyboard protocol:
      // - Physical key: backquote (keycode 96)
      // - Modifier: Shift
      // - Result: ~ (tilde)

      final backquoteCode = KeyMapping.keyCodeFor(LogicalKeyboardKey.backquote);
      expect(backquoteCode, 96);

      // The keyName should be the unshifted character
      final keyName = KeyMapping.keyNameFor(LogicalKeyboardKey.backquote);
      expect(keyName, '`');
    });

    test('all shifted punctuation keys use correct base keycodes', () {
      // These pairs share physical keys:
      // ~ / ` (96)
      // ! / 1 (49)
      // @ / 2 (50)
      // # / 3 (51)
      // $ / 4 (52)
      // % / 5 (53)
      // ^ / 6 (54)
      // & / 7 (55)
      // * / 8 (56)
      // ( / 9 (57)
      // ) / 0 (48)
      // _ / - (45)
      // + / = (61)
      // { / [ (91)
      // } / ] (93)
      // | / \ (92)
      // : / ; (59)
      // " / ' (39)
      // < / , (44)
      // > / . (46)
      // ? / / (47)

      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.backquote), 96);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.digit1), 49);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.digit2), 50);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.minus), 45);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.equal), 61);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.bracketLeft), 91);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.bracketRight), 93);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.backslash), 92);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.semicolon), 59);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.quote), 39);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.comma), 44);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.period), 46);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.slash), 47);
    });

    test('modifier keys are properly defined', () {
      // Ensure Shift keys are in the scancode map
      final shiftLeftCode = KeyMapping.keyCodeFor(LogicalKeyboardKey.shiftLeft);
      final shiftRightCode =
          KeyMapping.keyCodeFor(LogicalKeyboardKey.shiftRight);

      // These should be scancode-based (with 0x40000000 mask)
      expect(shiftLeftCode, greaterThan(0));
      expect(shiftRightCode, greaterThan(0));
    });
  });
}
