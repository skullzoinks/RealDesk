import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:realdesk/input/uiohook_ffi.dart';

void main() {
  group('UiohookFFI', () {
    test('SDL to uiohook key code conversion', () {
      // Test letter keys
      expect(sdlToUiohookKeycode(97), VC_A); // 'a'
      expect(sdlToUiohookKeycode(122), VC_Z); // 'z'

      // Test number keys
      expect(sdlToUiohookKeycode(48), VC_0);
      expect(sdlToUiohookKeycode(57), VC_9);

      // Test special keys
      expect(sdlToUiohookKeycode(13), VC_ENTER);
      expect(sdlToUiohookKeycode(32), VC_SPACE);
      expect(sdlToUiohookKeycode(9), VC_TAB);
      expect(sdlToUiohookKeycode(27), VC_ESCAPE);

      // Test arrow keys
      expect(sdlToUiohookKeycode(1073741906), VC_UP);
      expect(sdlToUiohookKeycode(1073741905), VC_DOWN);
      expect(sdlToUiohookKeycode(1073741904), VC_LEFT);
      expect(sdlToUiohookKeycode(1073741903), VC_RIGHT);

      // Test function keys
      expect(sdlToUiohookKeycode(1073741882), VC_F1);
      expect(sdlToUiohookKeycode(1073741893), VC_F12);

      // Test undefined key
      expect(sdlToUiohookKeycode(99999), VC_UNDEFINED);
    });

    test('Event type constants are defined', () {
      expect(EVENT_KEY_PRESSED, 4);
      expect(EVENT_KEY_RELEASED, 5);
      expect(EVENT_MOUSE_PRESSED, 7);
      expect(EVENT_MOUSE_RELEASED, 8);
      expect(EVENT_MOUSE_MOVED, 9);
      expect(EVENT_MOUSE_WHEEL, 11);
    });

    test('Modifier masks are defined', () {
      expect(MASK_SHIFT, MASK_SHIFT_L | MASK_SHIFT_R);
      expect(MASK_CTRL, MASK_CTRL_L | MASK_CTRL_R);
      expect(MASK_ALT, MASK_ALT_L | MASK_ALT_R);
      expect(MASK_META, MASK_META_L | MASK_META_R);
    });

    test('Mouse button constants are defined', () {
      expect(MOUSE_NOBUTTON, 0);
      expect(MOUSE_BUTTON1, 1);
      expect(MOUSE_BUTTON2, 2);
      expect(MOUSE_BUTTON3, 3);
    });

    // Only run FFI initialization test on desktop platforms
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      test('UiohookBindings initialization fails gracefully without library',
          () {
        // In test environment, library won't be available
        expect(
          () => UiohookBindings.instance,
          throwsA(isA<UnsupportedError>()),
        );
      });
    }
  });
}
