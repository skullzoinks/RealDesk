import 'dart:async';

import 'package:logger/logger.dart';

/// Stub Windows gamepad bridge used on platforms where dart:ffi is unavailable.
class WindowsGamepadBridge {
  WindowsGamepadBridge(Logger _);

  Stream<Map<String, dynamic>> get events =>
      const Stream<Map<String, dynamic>>.empty();

  void start() {}

  void dispose() {}
}
