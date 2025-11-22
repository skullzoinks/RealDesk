import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A gesture detector that only responds to touch events.
/// Mouse events are ignored (for gesture purposes) and can be forwarded to a callback.
class TouchOnlyGestureDetector extends StatelessWidget {
  const TouchOnlyGestureDetector({
    Key? key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onSystemPointerEvent,
    this.behavior,
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final HitTestBehavior? behavior;

  /// Callback for pointer events that are NOT touch (e.g. mouse).
  /// This allows forwarding mouse events to the underlying system.
  final void Function(PointerEvent event)? onSystemPointerEvent;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: behavior ?? HitTestBehavior.deferToChild,
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          onSystemPointerEvent?.call(event);
        }
      },
      onPointerMove: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          onSystemPointerEvent?.call(event);
        }
      },
      onPointerUp: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          onSystemPointerEvent?.call(event);
        }
      },
      onPointerHover: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          onSystemPointerEvent?.call(event);
        }
      },
      onPointerSignal: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          onSystemPointerEvent?.call(event);
        }
      },
      child: RawGestureDetector(
        behavior: behavior,
        gestures: {
          _TouchOnlyTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              _TouchOnlyTapGestureRecognizer>(
            () => _TouchOnlyTapGestureRecognizer(debugOwner: this),
            (instance) {
              instance
                ..onTap = onTap
                ..onTapDown = onTapDown
                ..onTapUp = onTapUp
                ..onTapCancel = onTapCancel;
            },
          ),
          _TouchOnlyPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              _TouchOnlyPanGestureRecognizer>(
            () => _TouchOnlyPanGestureRecognizer(debugOwner: this),
            (instance) {
              instance
                ..onStart = onPanStart
                ..onUpdate = onPanUpdate
                ..onEnd = onPanEnd;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class _TouchOnlyTapGestureRecognizer extends TapGestureRecognizer {
  _TouchOnlyTapGestureRecognizer({Object? debugOwner})
      : super(debugOwner: debugOwner);

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}

class _TouchOnlyPanGestureRecognizer extends PanGestureRecognizer {
  _TouchOnlyPanGestureRecognizer({Object? debugOwner})
      : super(debugOwner: debugOwner);

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}
