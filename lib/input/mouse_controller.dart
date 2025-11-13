import 'dart:ui' show Size;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../webrtc/data_channel.dart';
import 'schema/input_messages.dart';

/// Mouse input controller
class MouseController {
  static const double _wheelScale = 0.25;
  static const Duration _doubleClickThreshold = Duration(milliseconds: 500);
  static const double _doubleClickDistanceThreshold = 10.0;

  MouseController({
    required this.dataChannelManager,
    this.mode = MouseMode.absolute,
  }) : _logger = Logger();

  final DataChannelManager dataChannelManager;
  final Logger _logger;

  MouseMode mode;
  final Set<MouseButton> _pressedButtons = {};
  final Map<int, Set<MouseButton>> _pointerButtons = {};
  Size _remoteVideoSize = Size.zero;

  // Double-click detection state
  DateTime? _lastClickTime;
  Offset? _lastClickPosition;
  int _clickCount = 0;

  void updateRemoteVideoSize(Size size) {
    if (size.isEmpty) {
      return;
    }
    _remoteVideoSize = size;
  }

  /// Handle pointer down event
  void onPointerDown(PointerDownEvent event, Size viewSize) {
    _updateButtonState(event);

    // Detect double-click for mouse devices
    final isMouseClick = event.kind == PointerDeviceKind.mouse &&
        _pressedButtons.contains(MouseButton.left);

    if (isMouseClick) {
      final now = DateTime.now();
      final position = event.localPosition;

      if (_lastClickTime != null &&
          _lastClickPosition != null &&
          now.difference(_lastClickTime!) <= _doubleClickThreshold) {
        final distance = (position - _lastClickPosition!).distance;
        if (distance <= _doubleClickDistanceThreshold) {
          _clickCount++;
        } else {
          _clickCount = 1;
        }
      } else {
        _clickCount = 1;
      }

      _lastClickTime = now;
      _lastClickPosition = position;

      _logger.d('Click count: $_clickCount at position: $position');
    }

    if (mode == MouseMode.absolute) {
      // Send pixel coordinates with local view size for remote-side scaling
      dataChannelManager.sendMouseAbs(
        x: event.localPosition.dx,
        y: event.localPosition.dy,
        displayW: viewSize.width.round(),
        displayH: viewSize.height.round(),
        buttons: _pressedButtons.map((b) => b.value).toList(),
      );
    } else {
      dataChannelManager.sendMouseRel(
        dx: 0,
        dy: 0,
        buttons: _pressedButtons.map((b) => b.value).toList(),
      );
    }

    _logger.d(
      'Pointer down: id=${event.pointer} kind=${event.kind} buttons=${_pressedButtons.map((b) => b.value).join(',')}',
    );
  }

  /// Handle pointer up event
  void onPointerUp(PointerUpEvent event, Size viewSize) {
    final wasDoubleClick = _clickCount >= 2;
    _updateButtonState(event);

    if (mode == MouseMode.absolute) {
      // For double-click, send down-up-down-up sequence
      if (wasDoubleClick && event.kind == PointerDeviceKind.mouse) {
        _logger.d('Double-click detected, sending sequence');
        // First click up (already happened in onPointerDown)
        _sendMouseAbsolute(event, viewSize);
        // Small delay, then second click down
        Future.delayed(const Duration(milliseconds: 10), () {
          dataChannelManager.sendMouseAbs(
            x: event.localPosition.dx,
            y: event.localPosition.dy,
            displayW: viewSize.width.round(),
            displayH: viewSize.height.round(),
            buttons: [MouseButton.left.value],
          );
          // Second click up
          Future.delayed(const Duration(milliseconds: 10), () {
            dataChannelManager.sendMouseAbs(
              x: event.localPosition.dx,
              y: event.localPosition.dy,
              displayW: viewSize.width.round(),
              displayH: viewSize.height.round(),
              buttons: [],
            );
          });
        });
        _clickCount = 0; // Reset after double-click
      } else {
        _sendMouseAbsolute(event, viewSize);
        _sendMouseAbsolute(event, viewSize);
      }
    } else {
      dataChannelManager.sendMouseRel(
        dx: 0,
        dy: 0,
        buttons: _pressedButtons.map((b) => b.value).toList(),
      );
    }

    _logger.d('Pointer up: id=${event.pointer} kind=${event.kind}');
  }

  /// Handle pointer move event
  void onPointerMove(PointerMoveEvent event, Size viewSize) {
    _updateButtonState(event);

    if (mode == MouseMode.absolute) {
      _sendMouseAbsolute(event, viewSize);
    } else {
      dataChannelManager.sendMouseRel(
        dx: event.delta.dx,
        dy: event.delta.dy,
        buttons: _pressedButtons.map((b) => b.value).toList(),
      );
    }
  }

  /// Handle pointer hover event (mouse move without a pressed button)
  void onPointerHover(PointerHoverEvent event, Size viewSize) {
    _updateButtonState(event);

    if (mode == MouseMode.absolute) {
      _sendMouseAbsolute(event, viewSize);
    } else {
      dataChannelManager.sendMouseRel(
        dx: event.delta.dx,
        dy: event.delta.dy,
        buttons: _pressedButtons.map((b) => b.value).toList(),
      );
    }
  }

  /// Handle pointer cancel event (e.g. system gesture interruption)
  void onPointerCancel(PointerCancelEvent event) {
    final buttons = _pointerButtons.remove(event.pointer);
    if (buttons != null) {
      _pressedButtons.removeAll(buttons);
    }
    _pressedButtons
      ..clear()
      ..addAll(_pointerButtons.values.expand((s) => s));
  }

  /// Handle scroll event
  void onPointerScroll(PointerScrollEvent event) {
    dataChannelManager.sendWheel(
      dx: event.scrollDelta.dx * _wheelScale,
      dy: event.scrollDelta.dy * _wheelScale,
    );
    _logger.d('Mouse scroll: ${event.scrollDelta}');
  }

  /// Toggle mouse mode
  void toggleMode() {
    mode = mode == MouseMode.absolute ? MouseMode.relative : MouseMode.absolute;
    dataChannelManager.toggleMouseMode();
    _logger.i('Mouse mode toggled to: $mode');
  }

  // Absolute mode now uses pixel coordinates with displayW/H to let receiver scale.

  void _sendMouseAbsolute(PointerEvent event, Size viewSize) {
    if (viewSize.isEmpty) {
      return;
    }

    final mapped = _mapToRemotePosition(event.localPosition, viewSize);
    final displaySize = _effectiveDisplaySize(viewSize);

    dataChannelManager.sendMouseAbs(
      x: mapped.dx,
      y: mapped.dy,
      displayW: displaySize.width.round(),
      displayH: displaySize.height.round(),
      buttons: _pressedButtons.map((b) => b.value).toList(),
    );
  }

  Offset _mapToRemotePosition(Offset local, Size viewSize) {
    Size displaySize = _remoteVideoSize;
    if (displaySize.width <= 0 || displaySize.height <= 0) {
      displaySize = viewSize;
    }

    double contentWidth = viewSize.width;
    double contentHeight = viewSize.height;
    double offsetX = 0;
    double offsetY = 0;

    if (_remoteVideoSize.width > 0 && _remoteVideoSize.height > 0) {
      final videoAspect = _remoteVideoSize.width / _remoteVideoSize.height;
      final viewAspect = viewSize.width / viewSize.height;

      if (videoAspect > viewAspect) {
        contentWidth = viewSize.width;
        contentHeight = contentWidth / videoAspect;
        offsetY = (viewSize.height - contentHeight) / 2;
      } else {
        contentHeight = viewSize.height;
        contentWidth = contentHeight * videoAspect;
        offsetX = (viewSize.width - contentWidth) / 2;
      }
    }

    final double clampedX = (local.dx - offsetX).clamp(0.0, contentWidth);
    final double clampedY = (local.dy - offsetY).clamp(0.0, contentHeight);

    final normalizedX = contentWidth == 0 ? 0.0 : clampedX / contentWidth;
    final normalizedY = contentHeight == 0 ? 0.0 : clampedY / contentHeight;

    final remoteX = normalizedX * displaySize.width;
    final remoteY = normalizedY * displaySize.height;

    return Offset(remoteX, remoteY);
  }

  Size _effectiveDisplaySize(Size viewSize) {
    if (_remoteVideoSize.width > 0 && _remoteVideoSize.height > 0) {
      return _remoteVideoSize;
    }
    return viewSize;
  }

  void _updateButtonState(PointerEvent event) {
    final touchLike = event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;

    final maskButtons = _buttonsFromMask(
      event.buttons,
      event.kind,
      fallbackToPrimary: touchLike && event.down,
    );

    if (maskButtons.isNotEmpty) {
      _pointerButtons[event.pointer] = maskButtons;
    } else if (!event.down) {
      _pointerButtons.remove(event.pointer);
    }

    _pressedButtons
      ..clear()
      ..addAll(_pointerButtons.values.expand((s) => s));
  }

  Set<MouseButton> _buttonsFromMask(
    int buttons,
    PointerDeviceKind kind, {
    bool fallbackToPrimary = false,
  }) {
    final result = <MouseButton>{};
    if (buttons & kPrimaryMouseButton != 0) result.add(MouseButton.left);
    if (buttons & kSecondaryMouseButton != 0) result.add(MouseButton.right);
    if (buttons & kMiddleMouseButton != 0) result.add(MouseButton.middle);
    if (buttons & kBackMouseButton != 0) result.add(MouseButton.back);
    if (buttons & kForwardMouseButton != 0) result.add(MouseButton.forward);

    if (result.isEmpty && fallbackToPrimary) {
      result.add(MouseButton.left);
    }

    return result;
  }
}
