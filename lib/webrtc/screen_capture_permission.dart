import 'package:flutter/services.dart';

class ScreenCapturePermissionManager {
  static const MethodChannel _channel =
      MethodChannel('com.example.realdesk/screen_capture');

  static Future<bool> requestPermission() async {
    try {
      final bool? granted =
          await _channel.invokeMethod('requestScreenCapturePermission');
      return granted ?? false;
    } on PlatformException catch (e) {
      print('Failed to request screen capture permission: ${e.message}');
      return false;
    }
  }

  static void setPermissionCallback(Function(bool granted) callback) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPermissionGranted':
          callback(true);
          break;
        case 'onPermissionDenied':
          callback(false);
          break;
        default:
          break;
      }
    });
  }
}
