// ignore_for_file: camel_case_types, non_constant_identifier_names, constant_identifier_names

import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// Event Types
const int EVENT_HOOK_ENABLED = 1;
const int EVENT_HOOK_DISABLED = 2;
const int EVENT_KEY_TYPED = 3;
const int EVENT_KEY_PRESSED = 4;
const int EVENT_KEY_RELEASED = 5;
const int EVENT_MOUSE_CLICKED = 6;
const int EVENT_MOUSE_PRESSED = 7;
const int EVENT_MOUSE_RELEASED = 8;
const int EVENT_MOUSE_MOVED = 9;
const int EVENT_MOUSE_DRAGGED = 10;
const int EVENT_MOUSE_WHEEL = 11;

// Virtual Key Codes - Escape
const int VC_ESCAPE = 0x0001;

// Function Keys
const int VC_F1 = 0x003B;
const int VC_F2 = 0x003C;
const int VC_F3 = 0x003D;
const int VC_F4 = 0x003E;
const int VC_F5 = 0x003F;
const int VC_F6 = 0x0040;
const int VC_F7 = 0x0041;
const int VC_F8 = 0x0042;
const int VC_F9 = 0x0043;
const int VC_F10 = 0x0044;
const int VC_F11 = 0x0057;
const int VC_F12 = 0x0058;

// Alphanumeric Keys
const int VC_BACKQUOTE = 0x0029;
const int VC_1 = 0x0002;
const int VC_2 = 0x0003;
const int VC_3 = 0x0004;
const int VC_4 = 0x0005;
const int VC_5 = 0x0006;
const int VC_6 = 0x0007;
const int VC_7 = 0x0008;
const int VC_8 = 0x0009;
const int VC_9 = 0x000A;
const int VC_0 = 0x000B;

const int VC_MINUS = 0x000C;
const int VC_EQUALS = 0x000D;
const int VC_BACKSPACE = 0x000E;
const int VC_TAB = 0x000F;
const int VC_CAPS_LOCK = 0x003A;

// Letters A-Z
const int VC_A = 0x001E;
const int VC_B = 0x0030;
const int VC_C = 0x002E;
const int VC_D = 0x0020;
const int VC_E = 0x0012;
const int VC_F = 0x0021;
const int VC_G = 0x0022;
const int VC_H = 0x0023;
const int VC_I = 0x0017;
const int VC_J = 0x0024;
const int VC_K = 0x0025;
const int VC_L = 0x0026;
const int VC_M = 0x0032;
const int VC_N = 0x0031;
const int VC_O = 0x0018;
const int VC_P = 0x0019;
const int VC_Q = 0x0010;
const int VC_R = 0x0013;
const int VC_S = 0x001F;
const int VC_T = 0x0014;
const int VC_U = 0x0016;
const int VC_V = 0x002F;
const int VC_W = 0x0011;
const int VC_X = 0x002D;
const int VC_Y = 0x0015;
const int VC_Z = 0x002C;

const int VC_OPEN_BRACKET = 0x001A;
const int VC_CLOSE_BRACKET = 0x001B;
const int VC_BACK_SLASH = 0x002B;
const int VC_SEMICOLON = 0x0027;
const int VC_QUOTE = 0x0028;
const int VC_ENTER = 0x001C;
const int VC_COMMA = 0x0033;
const int VC_PERIOD = 0x0034;
const int VC_SLASH = 0x0035;
const int VC_SPACE = 0x0039;

// Special Keys
const int VC_PRINTSCREEN = 0x0E37;
const int VC_SCROLL_LOCK = 0x0046;
const int VC_PAUSE = 0x0E45;

// Edit Keys
const int VC_INSERT = 0x0E52;
const int VC_DELETE = 0x0E53;
const int VC_HOME = 0x0E47;
const int VC_END = 0x0E4F;
const int VC_PAGE_UP = 0x0E49;
const int VC_PAGE_DOWN = 0x0E51;

// Cursor Keys
const int VC_UP = 0xE048;
const int VC_LEFT = 0xE04B;
const int VC_CLEAR = 0xE04C;
const int VC_RIGHT = 0xE04D;
const int VC_DOWN = 0xE050;

// Numeric Keypad
const int VC_NUM_LOCK = 0x0045;
const int VC_KP_DIVIDE = 0x0E35;
const int VC_KP_MULTIPLY = 0x0037;
const int VC_KP_SUBTRACT = 0x004A;
const int VC_KP_ADD = 0x004E;
const int VC_KP_ENTER = 0x0E1C;
const int VC_KP_SEPARATOR = 0x0053;

// Modifier Keys
const int VC_SHIFT_L = 0x002A;
const int VC_SHIFT_R = 0x0036;
const int VC_CONTROL_L = 0x001D;
const int VC_CONTROL_R = 0x0E1D;
const int VC_ALT_L = 0x0038;
const int VC_ALT_R = 0x0E38;
const int VC_META_L = 0x0E5B;
const int VC_META_R = 0x0E5C;
const int VC_CONTEXT_MENU = 0x0E5D;

const int VC_UNDEFINED = 0x0000;
const int CHAR_UNDEFINED = 0xFFFF;

// Modifier Masks
const int MASK_SHIFT_L = 1 << 0;
const int MASK_CTRL_L = 1 << 1;
const int MASK_META_L = 1 << 2;
const int MASK_ALT_L = 1 << 3;
const int MASK_SHIFT_R = 1 << 4;
const int MASK_CTRL_R = 1 << 5;
const int MASK_META_R = 1 << 6;
const int MASK_ALT_R = 1 << 7;

const int MASK_SHIFT = MASK_SHIFT_L | MASK_SHIFT_R;
const int MASK_CTRL = MASK_CTRL_L | MASK_CTRL_R;
const int MASK_META = MASK_META_L | MASK_META_R;
const int MASK_ALT = MASK_ALT_L | MASK_ALT_R;

const int MASK_BUTTON1 = 1 << 8;
const int MASK_BUTTON2 = 1 << 9;
const int MASK_BUTTON3 = 1 << 10;
const int MASK_BUTTON4 = 1 << 11;
const int MASK_BUTTON5 = 1 << 12;

// Mouse Buttons
const int MOUSE_NOBUTTON = 0;
const int MOUSE_BUTTON1 = 1;
const int MOUSE_BUTTON2 = 2;
const int MOUSE_BUTTON3 = 3;
const int MOUSE_BUTTON4 = 4;
const int MOUSE_BUTTON5 = 5;

// Mouse Wheel
const int WHEEL_VERTICAL_DIRECTION = 3;
const int WHEEL_HORIZONTAL_DIRECTION = 4;

// FFI Structs
final class KeyboardEventData extends ffi.Struct {
  @ffi.UnsignedShort()
  external int keycode;
  @ffi.UnsignedShort()
  external int rawcode;
  @ffi.UnsignedShort()
  external int keychar;
}

final class MouseEventData extends ffi.Struct {
  @ffi.UnsignedShort()
  external int button;
  @ffi.UnsignedShort()
  external int clicks;
  @ffi.Short()
  external int x;
  @ffi.Short()
  external int y;
}

final class MouseWheelEventData extends ffi.Struct {
  @ffi.UnsignedShort()
  external int clicks;
  @ffi.Short()
  external int x;
  @ffi.Short()
  external int y;
  @ffi.UnsignedChar()
  external int type;
  @ffi.UnsignedShort()
  external int amount;
  @ffi.Short()
  external int rotation;
  @ffi.UnsignedChar()
  external int direction;
}

final class EventDataUnion extends ffi.Union {
  external KeyboardEventData keyboard;
  external MouseEventData mouse;
  external MouseWheelEventData wheel;
}

final class UiohookEvent extends ffi.Struct {
  @ffi.Int()
  external int type;
  @ffi.UnsignedLongLong()
  external int time;
  @ffi.UnsignedShort()
  external int mask;
  @ffi.UnsignedShort()
  external int reserved;
  external EventDataUnion data;
}

typedef HookPostEventNative = ffi.Void Function(ffi.Pointer<UiohookEvent>);
typedef HookPostEventDart = void Function(ffi.Pointer<UiohookEvent>);

class UiohookBindings {
  late final ffi.DynamicLibrary _lib;
  late final HookPostEventDart hook_post_event;

  UiohookBindings() {
    if (Platform.isMacOS) {
      // Try multiple paths for macOS
      final paths = [
        'libuiohook.dylib', // Current directory
        '@executable_path/../Frameworks/libuiohook.dylib', // App bundle
        Platform.resolvedExecutable
            .replaceAll('/realdesk', '/Frameworks/libuiohook.dylib'),
      ];

      bool loaded = false;
      Exception? lastError;

      for (final path in paths) {
        try {
          _lib = ffi.DynamicLibrary.open(path);
          // Try to lookup the symbol to verify library is correct
          _lib.lookup<ffi.NativeFunction<HookPostEventNative>>(
              'hook_post_event');
          loaded = true;
          break;
        } catch (e) {
          lastError = e as Exception;
        }
      }

      if (!loaded) {
        throw UnsupportedError(
            'libuiohook library not found. Tried: ${paths.join(', ')}\n'
            'Last error: $lastError');
      }
    } else if (Platform.isLinux) {
      _lib = ffi.DynamicLibrary.open('libuiohook.so');
    } else if (Platform.isWindows) {
      _lib = ffi.DynamicLibrary.open('uiohook.dll');
    } else {
      throw UnsupportedError('Platform not supported for libuiohook FFI');
    }

    hook_post_event = _lib
        .lookup<ffi.NativeFunction<HookPostEventNative>>('hook_post_event')
        .asFunction();
  }

  static final UiohookBindings _instance = UiohookBindings();
  static UiohookBindings get instance => _instance;
}

class UiohookEventHelper {
  static final _bindings = UiohookBindings.instance;

  static void postKeyboardEvent(int eventType, int keycode, int mask) {
    final event = calloc<UiohookEvent>();
    try {
      event.ref.type = eventType;
      event.ref.time = DateTime.now().millisecondsSinceEpoch;
      event.ref.mask = mask;
      event.ref.reserved = 0;
      event.ref.data.keyboard.keycode = keycode;
      event.ref.data.keyboard.rawcode = 0;
      event.ref.data.keyboard.keychar = CHAR_UNDEFINED;
      _bindings.hook_post_event(event);
    } finally {
      calloc.free(event);
    }
  }

  static void postMouseMoveEvent(int x, int y, int mask) {
    final event = calloc<UiohookEvent>();
    try {
      event.ref.type = EVENT_MOUSE_MOVED;
      event.ref.time = DateTime.now().millisecondsSinceEpoch;
      event.ref.mask = mask;
      event.ref.reserved = 0;
      event.ref.data.mouse.button = MOUSE_NOBUTTON;
      event.ref.data.mouse.clicks = 0;
      event.ref.data.mouse.x = x;
      event.ref.data.mouse.y = y;
      _bindings.hook_post_event(event);
    } finally {
      calloc.free(event);
    }
  }

  static void postMouseButtonEvent(
      int eventType, int button, int x, int y, int clicks, int mask) {
    final event = calloc<UiohookEvent>();
    try {
      event.ref.type = eventType;
      event.ref.time = DateTime.now().millisecondsSinceEpoch;
      event.ref.mask = mask;
      event.ref.reserved = 0;
      event.ref.data.mouse.button = button;
      event.ref.data.mouse.clicks = clicks;
      event.ref.data.mouse.x = x;
      event.ref.data.mouse.y = y;
      _bindings.hook_post_event(event);
    } finally {
      calloc.free(event);
    }
  }

  static void postMouseWheelEvent(
      int x, int y, int rotation, int direction, int mask) {
    final event = calloc<UiohookEvent>();
    try {
      event.ref.type = EVENT_MOUSE_WHEEL;
      event.ref.time = DateTime.now().millisecondsSinceEpoch;
      event.ref.mask = mask;
      event.ref.reserved = 0;
      event.ref.data.wheel.clicks = 1;
      event.ref.data.wheel.x = x;
      event.ref.data.wheel.y = y;
      event.ref.data.wheel.type = 1;
      event.ref.data.wheel.amount = 3;
      event.ref.data.wheel.rotation = rotation;
      event.ref.data.wheel.direction = direction;
      _bindings.hook_post_event(event);
    } finally {
      calloc.free(event);
    }
  }
}

int sdlToUiohookKeycode(int sdlCode) {
  switch (sdlCode) {
    // Special keys
    case 13:
      return VC_ENTER;
    case 9:
      return VC_TAB;
    case 32:
      return VC_SPACE;
    case 8:
      return VC_BACKSPACE;
    case 27:
      return VC_ESCAPE;

    // Function keys
    case 1073741882:
      return VC_F1;
    case 1073741883:
      return VC_F2;
    case 1073741884:
      return VC_F3;
    case 1073741885:
      return VC_F4;
    case 1073741886:
      return VC_F5;
    case 1073741887:
      return VC_F6;
    case 1073741888:
      return VC_F7;
    case 1073741889:
      return VC_F8;
    case 1073741890:
      return VC_F9;
    case 1073741891:
      return VC_F10;
    case 1073741892:
      return VC_F11;
    case 1073741893:
      return VC_F12;

    // Arrow keys
    case 1073741906:
      return VC_UP;
    case 1073741905:
      return VC_DOWN;
    case 1073741904:
      return VC_LEFT;
    case 1073741903:
      return VC_RIGHT;

    // Edit keys
    case 1073741898:
      return VC_HOME;
    case 1073741901:
      return VC_END;
    case 1073741899:
      return VC_PAGE_UP;
    case 1073741900:
      return VC_PAGE_DOWN;
    case 127:
      return VC_DELETE;
    case 1073741897:
      return VC_INSERT;

    // Modifier keys
    case 1073742049:
    case 1073742053:
      return VC_SHIFT_L;
    case 1073742048:
    case 1073742052:
      return VC_CONTROL_L;
    case 1073742050:
    case 1073742054:
      return VC_ALT_L;
    case 1073742051:
    case 1073742055:
      return VC_META_L;

    // Letters (SDL uses ASCII for a-z)
    case 97:
      return VC_A;
    case 98:
      return VC_B;
    case 99:
      return VC_C;
    case 100:
      return VC_D;
    case 101:
      return VC_E;
    case 102:
      return VC_F;
    case 103:
      return VC_G;
    case 104:
      return VC_H;
    case 105:
      return VC_I;
    case 106:
      return VC_J;
    case 107:
      return VC_K;
    case 108:
      return VC_L;
    case 109:
      return VC_M;
    case 110:
      return VC_N;
    case 111:
      return VC_O;
    case 112:
      return VC_P;
    case 113:
      return VC_Q;
    case 114:
      return VC_R;
    case 115:
      return VC_S;
    case 116:
      return VC_T;
    case 117:
      return VC_U;
    case 118:
      return VC_V;
    case 119:
      return VC_W;
    case 120:
      return VC_X;
    case 121:
      return VC_Y;
    case 122:
      return VC_Z;

    // Numbers
    case 48:
      return VC_0;
    case 49:
      return VC_1;
    case 50:
      return VC_2;
    case 51:
      return VC_3;
    case 52:
      return VC_4;
    case 53:
      return VC_5;
    case 54:
      return VC_6;
    case 55:
      return VC_7;
    case 56:
      return VC_8;
    case 57:
      return VC_9;

    // Punctuation
    case 45:
      return VC_MINUS;
    case 61:
      return VC_EQUALS;
    case 91:
      return VC_OPEN_BRACKET;
    case 93:
      return VC_CLOSE_BRACKET;
    case 92:
      return VC_BACK_SLASH;
    case 59:
      return VC_SEMICOLON;
    case 39:
      return VC_QUOTE;
    case 44:
      return VC_COMMA;
    case 46:
      return VC_PERIOD;
    case 47:
      return VC_SLASH;
    case 96:
      return VC_BACKQUOTE;

    default:
      return VC_UNDEFINED;
  }
}
