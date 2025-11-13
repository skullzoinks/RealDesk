import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 管理应用的屏幕方向
class OrientationManager {
  OrientationManager._();
  static final OrientationManager _instance = OrientationManager._();
  static OrientationManager get instance => _instance;

  /// 当前允许的屏幕方向
  List<DeviceOrientation> _allowedOrientations = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  /// 获取当前允许的屏幕方向
  List<DeviceOrientation> get allowedOrientations => _allowedOrientations;

  /// 设置允许的屏幕方向
  Future<void> setOrientations(List<DeviceOrientation> orientations) async {
    _allowedOrientations = orientations;
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// 锁定为横屏（左右）
  Future<void> lockToLandscape() async {
    await setOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// 锁定为竖屏（上下）
  Future<void> lockToPortrait() async {
    await setOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// 只允许竖屏向上
  Future<void> lockToPortraitUp() async {
    await setOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  /// 只允许横屏向左
  Future<void> lockToLandscapeLeft() async {
    await setOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
  }

  /// 只允许横屏向右
  Future<void> lockToLandscapeRight() async {
    await setOrientations([
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// 允许所有方向
  Future<void> allowAllOrientations() async {
    await setOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// 检查当前方向是否为横屏
  bool isLandscape(Orientation orientation) {
    return orientation == Orientation.landscape;
  }

  /// 检查当前方向是否为竖屏
  bool isPortrait(Orientation orientation) {
    return orientation == Orientation.portrait;
  }

  /// 切换到下一个可用方向
  Future<void> toggleOrientation() async {
    final currentOrientation =
        WidgetsBinding.instance.window.physicalSize.width >
                WidgetsBinding.instance.window.physicalSize.height
            ? Orientation.landscape
            : Orientation.portrait;

    if (isLandscape(currentOrientation)) {
      // 当前是横屏，切换到竖屏
      await lockToPortrait();
    } else {
      // 当前是竖屏，切换到横屏
      await lockToLandscape();
    }
  }

  /// 根据视频尺寸自动调整屏幕方向
  Future<void> adjustOrientationForVideo(
      int videoWidth, int videoHeight) async {
    if (videoWidth <= 0 || videoHeight <= 0) {
      return;
    }

    final aspectRatio = videoWidth / videoHeight;

    // 如果视频是横向的（宽高比 > 1.3），锁定为横屏
    if (aspectRatio > 1.3) {
      await lockToLandscape();
    }
    // 如果视频是竖向的（宽高比 < 0.7），锁定为竖屏
    else if (aspectRatio < 0.7) {
      await lockToPortrait();
    }
    // 否则允许所有方向
    else {
      await allowAllOrientations();
    }
  }

  /// 获取当前屏幕方向的描述
  String getOrientationDescription(Orientation orientation) {
    return isLandscape(orientation) ? '横屏' : '竖屏';
  }

  /// 获取建议的屏幕方向图标
  IconData getOrientationIcon(Orientation orientation) {
    return isLandscape(orientation)
        ? Icons.screen_rotation
        : Icons.screen_lock_rotation;
  }

  /// 恢复默认方向设置
  Future<void> resetToDefault() async {
    await setOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }
}
