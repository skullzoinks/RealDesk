/// Shared axis indices used by both Android and Windows gamepad adapters.
class GamepadAxisIndex {
  static const int lx = 0;
  static const int ly = 1;
  static const int rx = 3;
  static const int ry = 4;
  static const int lt = 6;
  static const int rt = 7;
  static const int hatX = 10;
  static const int hatY = 11;
}

/// XUSB button mask constants (mirrors remote/proto/xusb.h).
class XUsbButtons {
  static const int dpadUp = 0x0001;
  static const int dpadDown = 0x0002;
  static const int dpadLeft = 0x0004;
  static const int dpadRight = 0x0008;
  static const int start = 0x0010;
  static const int back = 0x0020;
  static const int leftThumb = 0x0040;
  static const int rightThumb = 0x0080;
  static const int leftShoulder = 0x0100;
  static const int rightShoulder = 0x0200;
  static const int guide = 0x0400;
  static const int a = 0x1000;
  static const int b = 0x2000;
  static const int x = 0x4000;
  static const int y = 0x8000;
}

/// Mapping from Android HardwareInputPlugin button indices to XUSB mask bits.
const Map<int, int> kAndroidButtonIndexToMask = {
  0: XUsbButtons.a, // KEYCODE_BUTTON_A
  1: XUsbButtons.b,
  2: XUsbButtons.x,
  3: XUsbButtons.y,
  4: XUsbButtons.leftShoulder,
  5: XUsbButtons.rightShoulder,
  8: XUsbButtons.leftThumb,
  9: XUsbButtons.rightThumb,
  10: XUsbButtons.start,
  11: XUsbButtons.back,
  12: XUsbButtons.guide,
  13: XUsbButtons.dpadUp,
  14: XUsbButtons.dpadDown,
  15: XUsbButtons.dpadLeft,
  16: XUsbButtons.dpadRight,
};
