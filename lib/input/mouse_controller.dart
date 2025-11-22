import 'package:flutter/gestures.dart';
import 'package:logger/logger.dart';

import '../webrtc/data_channel.dart';
import 'mouse_geometry.dart';
import 'schema/input_messages.dart';

/// Mouse input controller
class MouseController {
  static const double _wheelScale =
      1.0; // Increased from 0.25 for better trackpad response
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

  // Double-click detection state
  DateTime? _lastClickTime;
  Offset? _lastClickPosition;
  int _clickCount = 0;

  // Touch gesture state
  final Map<int, _TouchInfo> _activeTouches = {};
  DateTime? _twoFingerDownTime;
  Offset? _twoFingerInitialCenter;
  bool _isDragging = false;
  bool _isTwoFingerScrolling = false;
  static const Duration _twoFingerRightClickThreshold =
      Duration(milliseconds: 300);
  static const double _dragStartThreshold = 5.0;
  static const double _twoFingerScrollThreshold = 10.0;

  /// Handle pointer down event
  void onPointerDown(
    PointerDownEvent event,
    MouseDisplayGeometry geometry,
  ) {
    if (!geometry.hasVideoContent) {
      return;
    }

    final isTouchDevice = event.kind == PointerDeviceKind.touch;

    if (isTouchDevice) {
      // Track touch info
      _activeTouches[event.pointer] = _TouchInfo(
        position: event.localPosition,
        timestamp: DateTime.now(),
      );

      final touchCount = _activeTouches.length;

      if (touchCount == 1) {
        // Single finger: start tracking for click/double-click/drag
        _isDragging = false;
        _handleSingleFingerDown(event, geometry);
      } else if (touchCount == 2) {
        // Two fingers: prepare for right-click or scroll
        _twoFingerDownTime = DateTime.now();
        _twoFingerInitialCenter = _getTwoFingerCenter();
        _isTwoFingerScrolling = false;
        _logger.d('Two fingers detected at center: $_twoFingerInitialCenter');
      }
    } else {
      // Mouse device: use original logic
      _updateButtonState(event);

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

      // Send mouse event with current button state
      if (mode == MouseMode.absolute) {
        _sendMouseAbsolute(event, geometry);
      } else {
        dataChannelManager.sendMouseRel(
          dx: 0,
          dy: 0,
          buttons: _pressedButtons.map((b) => b.value).toList(),
        );
      }
    }

    _logger.d(
      'Pointer down: id=${event.pointer} kind=${event.kind} touches=${_activeTouches.length}',
    );
  }

  /// Handle pointer up event
  void onPointerUp(PointerUpEvent event, MouseDisplayGeometry geometry) {
    if (!geometry.hasVideoContent) {
      return;
    }
    final isTouchDevice = event.kind == PointerDeviceKind.touch;

    if (isTouchDevice) {
      final touchInfo = _activeTouches.remove(event.pointer);
      final touchCount = _activeTouches.length;

      if (touchInfo != null && touchCount == 0) {
        // Last finger released
        if (_isDragging) {
          // Release drag
          _handleDragEnd(event, geometry);
        } else if (_twoFingerDownTime != null) {
          // Two-finger gesture ended
          _handleTwoFingerUp(event, geometry);
        } else {
          // Single tap or double tap
          _handleSingleFingerUp(event, geometry, touchInfo);
        }
      }

      // Reset two-finger state only when all touches are released
      if (touchCount == 0) {
        _twoFingerDownTime = null;
        _twoFingerInitialCenter = null;
        _isTwoFingerScrolling = false;
      }
    } else {
      // Mouse device: use original logic
      _updateButtonState(event);

      if (mode == MouseMode.absolute) {
        _sendMouseAbsolute(event, geometry);
      } else {
        dataChannelManager.sendMouseRel(
          dx: 0,
          dy: 0,
          buttons: _pressedButtons.map((b) => b.value).toList(),
        );
      }
    }

    _logger.d(
      'Pointer up: id=${event.pointer} kind=${event.kind} touches=${_activeTouches.length}',
    );
  }

  /// Handle pointer move event
  void onPointerMove(PointerMoveEvent event, MouseDisplayGeometry geometry) {
    if (!geometry.hasVideoContent) {
      return;
    }
    final isTouchDevice = event.kind == PointerDeviceKind.touch;

    if (isTouchDevice) {
      // Update touch position
      final touchInfo = _activeTouches[event.pointer];
      if (touchInfo != null) {
        _activeTouches[event.pointer] = touchInfo.copyWith(
          position: event.localPosition,
        );
      }

      final touchCount = _activeTouches.length;

      if (touchCount == 1) {
        // Single finger move: check for drag
        _handleSingleFingerMove(event, geometry);
      } else if (touchCount == 2) {
        // Two finger move: scroll
        _handleTwoFingerMove(event, geometry);
      }
    } else {
      // Mouse device: use original logic
      _updateButtonState(event);

      if (mode == MouseMode.absolute) {
        _sendMouseAbsolute(event, geometry);
      } else {
        final scaledDelta = geometry.scaleRelativeDelta(event.delta);
        dataChannelManager.sendMouseRel(
          dx: scaledDelta.dx,
          dy: scaledDelta.dy,
          buttons: _pressedButtons.map((b) => b.value).toList(),
        );
        _logger.d(
          'Relative move: original=(${event.delta.dx.toStringAsFixed(1)}, ${event.delta.dy.toStringAsFixed(1)}), '
          'scaled=(${scaledDelta.dx.toStringAsFixed(1)}, ${scaledDelta.dy.toStringAsFixed(1)})',
        );
      }
    }
  }

  /// Handle pointer hover event (mouse move without a pressed button)
  void onPointerHover(PointerHoverEvent event, MouseDisplayGeometry geometry) {
    if (!geometry.hasVideoContent) {
      return;
    }
    _updateButtonState(event);

    if (mode == MouseMode.absolute) {
      _sendMouseAbsolute(event, geometry);
    } else {
      // Scale delta based on video size ratio
      final scaledDelta = geometry.scaleRelativeDelta(event.delta);
      dataChannelManager.sendMouseRel(
        dx: scaledDelta.dx,
        dy: scaledDelta.dy,
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
    // On macOS trackpad, scrollDelta values are in logical pixels
    // and can be fractional for smooth scrolling
    // Adjust scale based on scroll delta magnitude for better responsiveness
    double scale = _wheelScale;

    // For very small deltas (smooth trackpad scrolling), use higher multiplier
    final magnitude = event.scrollDelta.distance;
    if (magnitude < 10) {
      scale = _wheelScale * 2.0; // Boost small movements
    }

    dataChannelManager.sendWheel(
      dx: event.scrollDelta.dx * scale,
      dy: event.scrollDelta.dy * scale,
    );
    _logger.d('Scroll: delta=${event.scrollDelta}, scale=$scale');
  }

  /// Toggle mouse mode
  void toggleMode() {
    mode = mode == MouseMode.absolute ? MouseMode.relative : MouseMode.absolute;
    dataChannelManager.toggleMouseMode();
    _logger.i('Mouse mode toggled to: $mode');
  }

  // Absolute mode now uses pixel coordinates with displayW/H to let receiver scale.
  void _sendMouseAbsolute(
    PointerEvent event,
    MouseDisplayGeometry geometry,
  ) {
    if (!geometry.hasVideoContent) {
      return;
    }

    final mapped = geometry.mapLocalToRemote(event.localPosition);
    final displaySize = geometry.remoteDisplaySize;

    dataChannelManager.sendMouseAbs(
      x: mapped.dx,
      y: mapped.dy,
      displayW: displaySize.width.round(),
      displayH: displaySize.height.round(),
      buttons: _pressedButtons.map((b) => b.value).toList(),
    );
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

  // Touch gesture handlers

  void _handleSingleFingerDown(
    PointerDownEvent event,
    MouseDisplayGeometry geometry,
  ) {
    // Just move cursor to position, don't press button yet
    if (mode == MouseMode.absolute) {
      _sendMouseAbsolute(event, geometry);
    }
  }

  void _handleSingleFingerUp(
    PointerUpEvent event,
    MouseDisplayGeometry geometry,
    _TouchInfo touchInfo,
  ) {
    final distance = (event.localPosition - touchInfo.position).distance;

    // Check if it's a tap (not a drag)
    if (distance < _dragStartThreshold) {
      // Detect double-tap
      final now = DateTime.now();
      final isDoubleTap = _lastClickTime != null &&
          _lastClickPosition != null &&
          now.difference(_lastClickTime!) <= _doubleClickThreshold &&
          (event.localPosition - _lastClickPosition!).distance <=
              _doubleClickDistanceThreshold;

      if (isDoubleTap) {
        _logger.d('Double-tap detected');
        // Send double-click
        _sendClick(event, geometry, MouseButton.left);
        _sendClick(event, geometry, MouseButton.left);
        _lastClickTime = null;
        _lastClickPosition = null;
      } else {
        _logger.d('Single tap detected');
        // Send single click
        _sendClick(event, geometry, MouseButton.left);
        _lastClickTime = now;
        _lastClickPosition = event.localPosition;
      }
    }
  }

  void _handleSingleFingerMove(
    PointerMoveEvent event,
    MouseDisplayGeometry geometry,
  ) {
    final firstTouch = _activeTouches.values.first;
    final distance = (event.localPosition - firstTouch.position).distance;

    if (!_isDragging && distance > _dragStartThreshold) {
      // Start dragging
      _isDragging = true;
      _logger.d('Drag started');
      // Press left button
      if (mode == MouseMode.absolute) {
        final mappedPos = geometry.mapLocalToRemote(firstTouch.position);
        final displaySize = geometry.remoteDisplaySize;
        dataChannelManager.sendMouseAbs(
          x: mappedPos.dx,
          y: mappedPos.dy,
          displayW: displaySize.width.round(),
          displayH: displaySize.height.round(),
          buttons: [MouseButton.left.value],
        );
      }
    }

    if (_isDragging) {
      // Continue drag
      if (mode == MouseMode.absolute) {
        final mappedPos = geometry.mapLocalToRemote(event.localPosition);
        final displaySize = geometry.remoteDisplaySize;
        dataChannelManager.sendMouseAbs(
          x: mappedPos.dx,
          y: mappedPos.dy,
          displayW: displaySize.width.round(),
          displayH: displaySize.height.round(),
          buttons: [MouseButton.left.value],
        );
      } else {
        final scaledDelta = geometry.scaleRelativeDelta(event.delta);
        dataChannelManager.sendMouseRel(
          dx: scaledDelta.dx,
          dy: scaledDelta.dy,
          buttons: [MouseButton.left.value],
        );
      }
    } else {
      // Just move cursor without pressing
      if (mode == MouseMode.absolute) {
        _sendMouseAbsolute(event, geometry);
      } else {
        final scaledDelta = geometry.scaleRelativeDelta(event.delta);
        dataChannelManager.sendMouseRel(
          dx: scaledDelta.dx,
          dy: scaledDelta.dy,
          buttons: [],
        );
      }
    }
  }

  void _handleDragEnd(
    PointerUpEvent event,
    MouseDisplayGeometry geometry,
  ) {
    _logger.d('Drag ended');
    // Release left button
    if (mode == MouseMode.absolute) {
      final mappedPos = geometry.mapLocalToRemote(event.localPosition);
      final displaySize = geometry.remoteDisplaySize;
      dataChannelManager.sendMouseAbs(
        x: mappedPos.dx,
        y: mappedPos.dy,
        displayW: displaySize.width.round(),
        displayH: displaySize.height.round(),
        buttons: [],
      );
    } else {
      dataChannelManager.sendMouseRel(
        dx: 0,
        dy: 0,
        buttons: [],
      );
    }
    _isDragging = false;
  }

  void _handleTwoFingerUp(
    PointerUpEvent event,
    MouseDisplayGeometry geometry,
  ) {
    if (_twoFingerDownTime == null) return;

    final duration = DateTime.now().difference(_twoFingerDownTime!);

    if (!_isTwoFingerScrolling && duration <= _twoFingerRightClickThreshold) {
      // Quick two-finger tap = right click
      _logger.d('Two-finger right-click detected');
      _sendClick(event, geometry, MouseButton.right);
    }

    _twoFingerDownTime = null;
    _twoFingerInitialCenter = null;
    _isTwoFingerScrolling = false;
  }

  void _handleTwoFingerMove(
    PointerMoveEvent event,
    MouseDisplayGeometry _,
  ) {
    if (_twoFingerInitialCenter == null) return;

    final currentCenter = _getTwoFingerCenter();
    if (currentCenter == null) return;

    final delta = currentCenter - _twoFingerInitialCenter!;
    final distance = delta.distance;

    if (!_isTwoFingerScrolling && distance > _twoFingerScrollThreshold) {
      _isTwoFingerScrolling = true;
      _logger.d('Two-finger scroll started');
    }

    if (_isTwoFingerScrolling) {
      // Send scroll event
      dataChannelManager.sendWheel(
        dx: delta.dx * _wheelScale,
        dy: delta.dy * _wheelScale,
      );
      _twoFingerInitialCenter = currentCenter;
    }
  }

  void _sendClick(
    PointerEvent event,
    MouseDisplayGeometry geometry,
    MouseButton button,
  ) {
    if (mode == MouseMode.absolute) {
      final mappedPos = geometry.mapLocalToRemote(event.localPosition);
      final displaySize = geometry.remoteDisplaySize;

      // Press
      dataChannelManager.sendMouseAbs(
        x: mappedPos.dx,
        y: mappedPos.dy,
        displayW: displaySize.width.round(),
        displayH: displaySize.height.round(),
        buttons: [button.value],
      );

      // Release (small delay to ensure press is registered)
      Future.delayed(const Duration(milliseconds: 50), () {
        dataChannelManager.sendMouseAbs(
          x: mappedPos.dx,
          y: mappedPos.dy,
          displayW: displaySize.width.round(),
          displayH: displaySize.height.round(),
          buttons: [],
        );
      });
    } else {
      // Relative mode: press and release
      dataChannelManager.sendMouseRel(
        dx: 0,
        dy: 0,
        buttons: [button.value],
      );
      Future.delayed(const Duration(milliseconds: 50), () {
        dataChannelManager.sendMouseRel(
          dx: 0,
          dy: 0,
          buttons: [],
        );
      });
    }
  }

  Offset? _getTwoFingerCenter() {
    if (_activeTouches.length != 2) return null;

    final positions = _activeTouches.values.map((t) => t.position).toList();
    return Offset(
      (positions[0].dx + positions[1].dx) / 2,
      (positions[0].dy + positions[1].dy) / 2,
    );
  }

  /// Send a specific mouse button event (down/up)
  void sendButton(int button, bool down) {
    final mouseButton = MouseButton.values.firstWhere(
      (b) => b.value == button,
      orElse: () => MouseButton.left,
    );

    if (down) {
      _pressedButtons.add(mouseButton);
    } else {
      _pressedButtons.remove(mouseButton);
    }

    // Send update
    dataChannelManager.sendMouseRel(
      dx: 0,
      dy: 0,
      buttons: _pressedButtons.map((b) => b.value).toList(),
    );
  }
}

class _TouchInfo {
  final Offset position;
  final DateTime timestamp;

  _TouchInfo({
    required this.position,
    required this.timestamp,
  });

  _TouchInfo copyWith({
    Offset? position,
    DateTime? timestamp,
  }) {
    return _TouchInfo(
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
