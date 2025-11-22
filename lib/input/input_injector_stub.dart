import 'package:logger/logger.dart';

/// No-op input injector used on platforms that do not support native input
/// injection (such as Flutter Web).
class InputInjector {
  InputInjector() : _logger = Logger();

  final Logger _logger;

  Future<bool> initialize() async {
    _logger.i('Input injector stub initialized (no native input available)');
    return false;
  }

  Future<void> injectMouseAbsolute({
    required double x,
    required double y,
    required int displayW,
    required int displayH,
    required int buttons,
  }) async {
    _logger.d('Stub mouse abs event ignored');
  }

  Future<void> injectMouseRelative({
    required double dx,
    required double dy,
    required int buttons,
  }) async {
    _logger.d('Stub mouse rel event ignored');
  }

  Future<void> injectMouseWheel({
    required double dx,
    required double dy,
  }) async {
    _logger.d('Stub mouse wheel event ignored');
  }

  Future<void> injectKeyboard({
    required String key,
    required int code,
    required bool down,
    required int mods,
  }) async {
    _logger.d('Stub keyboard event ignored');
  }

  Future<void> injectTouch({
    required List<Map<String, dynamic>> touches,
  }) async {
    _logger.d('Stub touch event ignored');
  }

  void dispose() {
    _logger.i('Input injector stub disposed');
  }
}
