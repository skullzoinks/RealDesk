import 'dart:ui';

import '../models/display_mode.dart';

/// Describes how the remote video is displayed inside the local view.
///
/// The logic mirrors the coordinate mapping rules in
/// `remote/common/geometry.h` so that (local -> remote) conversions stay
/// numerically stable for both JSON and protobuf transports.
class MouseDisplayGeometry {
  const MouseDisplayGeometry({
    required this.viewSize,
    required this.remoteVideoSize,
    required this.videoRect,
  });

  /// Empty geometry placeholder.
  const MouseDisplayGeometry.empty()
      : viewSize = Size.zero,
        remoteVideoSize = Size.zero,
        videoRect = Rect.zero;

  final Size viewSize;
  final Size remoteVideoSize;

  /// Rectangle (in local widget coordinates) that actually renders the remote
  /// frame after accounting for letterboxing or forced aspect ratios.
  final Rect videoRect;

  /// Builds geometry for the current view/layout configuration.
  factory MouseDisplayGeometry.compute({
    required Size viewSize,
    required Size remoteVideoSize,
    required DisplayMode displayMode,
    bool forceMobileWide = false,
    double forcedAspectRatio = 20 / 9,
  }) {
    if (viewSize.isEmpty) {
      return const MouseDisplayGeometry.empty();
    }

    final hasRemoteSize =
        remoteVideoSize.width > 0 && remoteVideoSize.height > 0;
    final aspectSource = hasRemoteSize ? remoteVideoSize : viewSize;
    final remoteAspect = _aspectRatio(aspectSource);

    Rect rect;
    if (forceMobileWide) {
      final outerRect = _letterboxedRect(viewSize, forcedAspectRatio);
      final innerRect = _letterboxedRect(
        Size(outerRect.width, outerRect.height),
        remoteAspect,
      );
      rect = innerRect.shift(outerRect.topLeft);
    } else if (displayMode == DisplayMode.contain) {
      rect = _letterboxedRect(viewSize, remoteAspect);
    } else {
      rect = Rect.fromLTWH(0, 0, viewSize.width, viewSize.height);
    }

    return MouseDisplayGeometry(
      viewSize: viewSize,
      remoteVideoSize: remoteVideoSize,
      videoRect: rect,
    );
  }

  bool get hasRemoteVideoSize =>
      remoteVideoSize.width > 0 && remoteVideoSize.height > 0;

  bool get hasVideoContent => videoRect.width > 0 && videoRect.height > 0;

  Size get remoteDisplaySize => hasRemoteVideoSize ? remoteVideoSize : viewSize;

  /// Clamp a local point so it stays inside the displayed video rectangle.
  Offset clampLocal(Offset local) {
    if (!hasVideoContent) {
      return Offset.zero;
    }
    final clampedX =
        (local.dx - videoRect.left).clamp(0.0, videoRect.width).toDouble();
    final clampedY =
        (local.dy - videoRect.top).clamp(0.0, videoRect.height).toDouble();
    return Offset(videoRect.left + clampedX, videoRect.top + clampedY);
  }

  /// Convert a local coordinate to the remote desktop pixel coordinate space.
  Offset mapLocalToRemote(Offset local) {
    if (!hasVideoContent) {
      return Offset.zero;
    }
    final clamped = clampLocal(local);
    final normalizedX = videoRect.width == 0
        ? 0.0
        : (clamped.dx - videoRect.left) / videoRect.width;
    final normalizedY = videoRect.height == 0
        ? 0.0
        : (clamped.dy - videoRect.top) / videoRect.height;
    final displaySize = remoteDisplaySize;
    return Offset(
      normalizedX * displaySize.width,
      normalizedY * displaySize.height,
    );
  }

  /// Convert a remote desktop pixel coordinate back to local view space to
  /// render the cursor overlay.
  Offset mapRemoteToLocal({
    required double remoteX,
    required double remoteY,
    double? displayW,
    double? displayH,
  }) {
    if (!hasVideoContent) {
      return Offset.zero;
    }
    final effectiveDisplayW = (displayW == null || displayW <= 0)
        ? remoteDisplaySize.width
        : displayW;
    final effectiveDisplayH = (displayH == null || displayH <= 0)
        ? remoteDisplaySize.height
        : displayH;

    final normalizedX =
        effectiveDisplayW == 0 ? 0.0 : remoteX / effectiveDisplayW;
    final normalizedY =
        effectiveDisplayH == 0 ? 0.0 : remoteY / effectiveDisplayH;

    return Offset(
      videoRect.left + normalizedX * videoRect.width,
      videoRect.top + normalizedY * videoRect.height,
    );
  }

  /// Scale a relative delta so it matches the remote pixel density.
  Offset scaleRelativeDelta(Offset delta) {
    if (!hasVideoContent) {
      return delta;
    }
    final displaySize = remoteDisplaySize;
    final scaleX =
        videoRect.width == 0 ? 1.0 : displaySize.width / videoRect.width;
    final scaleY =
        videoRect.height == 0 ? 1.0 : displaySize.height / videoRect.height;
    return Offset(delta.dx * scaleX, delta.dy * scaleY);
  }

  static Rect _letterboxedRect(Size container, double contentAspect) {
    final containerAspect =
        container.height == 0 ? 1.0 : container.width / container.height;

    if (contentAspect > containerAspect) {
      final width = container.width;
      final height = width / contentAspect;
      final offsetY = (container.height - height) / 2;
      return Rect.fromLTWH(0, offsetY, width, height);
    } else {
      final height = container.height;
      final width = height * contentAspect;
      final offsetX = (container.width - width) / 2;
      return Rect.fromLTWH(offsetX, 0, width, height);
    }
  }

  static double _aspectRatio(Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return 1.0;
    }
    return size.width / size.height;
  }
}
