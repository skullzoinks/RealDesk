import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realdesk/input/key_mapping.dart';

void main() {
  group('KeyMapping', () {
    test('punctuation keys have correct ASCII codes', () {
      // Comma and period
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.comma), 44); // ,
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.period), 46); // .

      // Other punctuation
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.slash), 47); // /
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.semicolon), 59); // ;
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.minus), 45); // -
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.equal), 61); // =

      // Brackets and quotes
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.bracketLeft), 91); // [
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.bracketRight), 93); // ]
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.backslash), 92); // \
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.backquote), 96); // `
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.quote), 39); // '
    });

    test('letter keys have correct ASCII codes', () {
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.keyA), 97); // a
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.keyZ), 122); // z
    });

    test('number keys have correct ASCII codes', () {
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.digit0), 48); // 0
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.digit9), 57); // 9
    });

    test('special keys have correct codes', () {
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.enter), 13);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.tab), 9);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.space), 32);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.backspace), 8);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.escape), 27);
    });

    test('arrow keys have correct scancode-based codes', () {
      final sdlMask = 0x40000000;
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.arrowUp), sdlMask | 82);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.arrowDown), sdlMask | 81);
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.arrowLeft), sdlMask | 80);
      expect(
          KeyMapping.keyCodeFor(LogicalKeyboardKey.arrowRight), sdlMask | 79);
    });

    test('keyNameFor returns readable names', () {
      expect(KeyMapping.keyNameFor(LogicalKeyboardKey.comma), ',');
      expect(KeyMapping.keyNameFor(LogicalKeyboardKey.period), '.');
      expect(KeyMapping.keyNameFor(LogicalKeyboardKey.backquote), '`');
      // keyLabel returns uppercase for letters
      expect(KeyMapping.keyNameFor(LogicalKeyboardKey.keyA).toLowerCase(), 'a');
      expect(KeyMapping.keyNameFor(LogicalKeyboardKey.enter), isNotEmpty);
    });

    test('tilde (~) uses backquote key with Shift modifier', () {
      // Tilde (~) is produced by Shift + ` (backquote)
      // The key code should be ` (96), and Shift modifier should be set
      expect(KeyMapping.keyCodeFor(LogicalKeyboardKey.backquote), 96);
      // The actual ~ character depends on the Shift modifier being sent
    });
  });
}
