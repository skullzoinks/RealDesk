import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../input/keyboard_controller.dart';
import '../../input/mouse_controller.dart';
import '../../input/mouse_geometry.dart';
import 'touch_only_gesture_detector.dart';

class VirtualGameControls extends StatefulWidget {
  const VirtualGameControls({
    Key? key,
    required this.type,
    required this.keyboardController,
    required this.mouseController,
    required this.onClose,
    this.onSystemPointerEvent,
  }) : super(key: key);

  final String type; // 'cs2' or 'lol'
  final KeyboardController keyboardController;
  final MouseController mouseController;
  final VoidCallback onClose;
  final void Function(PointerEvent)? onSystemPointerEvent;

  @override
  State<VirtualGameControls> createState() => _VirtualGameControlsState();
}

class _VirtualGameControlsState extends State<VirtualGameControls> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mouse Trackpad Area (Right side for CS2, Full/Right for LOL)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.6,
          child: _GameTrackpad(
            mouseController: widget.mouseController,
            onTap: () {
              // Left click
              widget.mouseController.sendButton(1, true);
              Future.delayed(const Duration(milliseconds: 50), () {
                widget.mouseController.sendButton(1, false);
              });
            },
          ),
        ),

        // Close Button
        Positioned(
          top: 24,
          right: 24,
          child: SafeArea(
            child: FloatingActionButton.small(
              onPressed: widget.onClose,
              backgroundColor: Colors.red.withOpacity(0.8),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),

        // Game Specific Layouts
        if (widget.type == 'cs2') _buildCS2Layout(),
        if (widget.type == 'lol') _buildLOLLayout(),
      ],
    );
  }

  Widget _buildCS2Layout() {
    return Stack(
      children: [
        // WASD Joystick
        Positioned(
          left: 60,
          bottom: 60,
          child: _WASDJoystick(
            onKey: (key, down) =>
                widget.keyboardController.simulateKey(key, down),
            onSystemPointerEvent: widget.onSystemPointerEvent,
          ),
        ),

        // Action Buttons (Reload, Jump, Crouch, Walk)
        Positioned(
          left: 200,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GameButton(
                label: 'R',
                icon: Icons.sync,
                keyDef: LogicalKeyboardKey.keyR,
                controller: widget.keyboardController,
                color: Colors.yellow,
                onSystemPointerEvent: widget.onSystemPointerEvent,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _GameButton(
                    label: 'Crouch',
                    icon: Icons.keyboard_double_arrow_down,
                    keyDef: LogicalKeyboardKey.controlLeft,
                    controller: widget.keyboardController,
                    width: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _GameButton(
                    label: 'Jump',
                    icon: Icons.keyboard_double_arrow_up,
                    keyDef: LogicalKeyboardKey.space,
                    controller: widget.keyboardController,
                    width: 80,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Weapon Switching
        Positioned(
          left: 40,
          top: 100,
          child: Column(
            children: [
              _GameButton(
                label: '1',
                icon: Icons.filter_1,
                keyDef: LogicalKeyboardKey.digit1,
                controller: widget.keyboardController,
                size: 40,
              ),
              const SizedBox(height: 8),
              _GameButton(
                label: '2',
                icon: Icons.filter_2,
                keyDef: LogicalKeyboardKey.digit2,
                controller: widget.keyboardController,
                size: 40,
              ),
              const SizedBox(height: 8),
              _GameButton(
                label: '3',
                icon: Icons.filter_3,
                keyDef: LogicalKeyboardKey.digit3,
                controller: widget.keyboardController,
                size: 40,
              ),
              const SizedBox(height: 8),
              _GameButton(
                label: '4',
                icon: Icons.filter_4,
                keyDef: LogicalKeyboardKey.digit4,
                controller: widget.keyboardController,
                size: 40,
              ),
            ],
          ),
        ),

        // Scope / Right Click
        Positioned(
          right: 120,
          bottom: 100,
          child: _GameButton(
            label: 'SCOPE',
            icon: Icons.center_focus_weak,
            onDown: () =>
                widget.mouseController.sendButton(3, true), // Right click
            onUp: () => widget.mouseController.sendButton(3, false),
            color: Colors.orange,
            size: 60,
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Fire / Left Click (Large button)
        Positioned(
          right: 40,
          bottom: 160,
          child: _GameButton(
            label: 'FIRE',
            icon: Icons.my_location,
            onDown: () =>
                widget.mouseController.sendButton(1, true), // Left click
            onUp: () => widget.mouseController.sendButton(1, false),
            color: Colors.red,
            size: 80,
            gradient: const LinearGradient(
              colors: [Colors.redAccent, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Tab / Esc
        Positioned(
          left: 40,
          top: 40,
          child: Row(
            children: [
              _GameButton(
                label: 'ESC',
                icon: Icons.settings_power,
                keyDef: LogicalKeyboardKey.escape,
                controller: widget.keyboardController,
                width: 60,
                height: 30,
              ),
              const SizedBox(width: 16),
              _GameButton(
                label: 'TAB',
                icon: Icons.segment,
                keyDef: LogicalKeyboardKey.tab,
                controller: widget.keyboardController,
                width: 60,
                height: 30,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLOLLayout() {
    return Stack(
      children: [
        // QWER Skills
        Positioned(
          left: 40,
          bottom: 40,
          child: Row(
            children: [
              _GameButton(
                label: 'Q',
                icon: Icons.auto_awesome,
                keyDef: LogicalKeyboardKey.keyQ,
                controller: widget.keyboardController,
                size: 60,
                color: Colors.blue,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(width: 16),
              _GameButton(
                label: 'W',
                icon: Icons.shield,
                keyDef: LogicalKeyboardKey.keyW,
                controller: widget.keyboardController,
                size: 60,
                color: Colors.blue,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(width: 16),
              _GameButton(
                label: 'E',
                icon: Icons.explore,
                keyDef: LogicalKeyboardKey.keyE,
                controller: widget.keyboardController,
                size: 60,
                color: Colors.blue,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(width: 16),
              _GameButton(
                label: 'R',
                icon: Icons.whatshot,
                keyDef: LogicalKeyboardKey.keyR,
                controller: widget.keyboardController,
                size: 70,
                color: Colors.red,
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ],
          ),
        ),

        // Summoner Spells (D, F)
        Positioned(
          left: 40,
          bottom: 120,
          child: Row(
            children: [
              _GameButton(
                label: 'D',
                icon: Icons.flash_on,
                keyDef: LogicalKeyboardKey.keyD,
                controller: widget.keyboardController,
                size: 50,
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _GameButton(
                label: 'F',
                icon: Icons.healing,
                keyDef: LogicalKeyboardKey.keyF,
                controller: widget.keyboardController,
                size: 50,
                color: Colors.orange,
              ),
            ],
          ),
        ),

        // Items (1-6)
        Positioned(
          left: 40,
          top: 100,
          child: Wrap(
            direction: Axis.vertical,
            spacing: 8,
            children: [
              _GameButton(
                  label: '1',
                  icon: Icons.filter_1,
                  keyDef: LogicalKeyboardKey.digit1,
                  controller: widget.keyboardController,
                  size: 40),
              _GameButton(
                  label: '2',
                  icon: Icons.filter_2,
                  keyDef: LogicalKeyboardKey.digit2,
                  controller: widget.keyboardController,
                  size: 40),
              _GameButton(
                  label: '3',
                  icon: Icons.filter_3,
                  keyDef: LogicalKeyboardKey.digit3,
                  controller: widget.keyboardController,
                  size: 40),
              _GameButton(
                  label: '4',
                  icon: Icons.filter_4,
                  keyDef: LogicalKeyboardKey.digit4,
                  controller: widget.keyboardController,
                  size: 40),
              _GameButton(
                  label: '5',
                  icon: Icons.filter_5,
                  keyDef: LogicalKeyboardKey.digit5,
                  controller: widget.keyboardController,
                  size: 40),
              _GameButton(
                  label: '6',
                  icon: Icons.filter_6,
                  keyDef: LogicalKeyboardKey.digit6,
                  controller: widget.keyboardController,
                  size: 40),
            ],
          ),
        ),

        // Utility (B, P, Tab)
        Positioned(
          right: 120,
          bottom: 40,
          child: Row(
            children: [
              _GameButton(
                label: 'Recall',
                icon: Icons.home_filled,
                keyDef: LogicalKeyboardKey.keyB,
                controller: widget.keyboardController,
                width: 80,
              ),
              const SizedBox(width: 16),
              _GameButton(
                label: 'Shop',
                icon: Icons.storefront,
                keyDef: LogicalKeyboardKey.keyP,
                controller: widget.keyboardController,
                width: 60,
              ),
            ],
          ),
        ),

        // Mouse Buttons (Right Click for Move, Left Click for Select)
        Positioned(
          right: 40,
          bottom: 120,
          child: Column(
            children: [
              _GameButton(
                label: 'MOVE',
                icon: Icons.touch_app,
                onDown: () => widget.mouseController.sendButton(3, true),
                onUp: () => widget.mouseController.sendButton(3, false),
                color: Colors.green,
                width: 120,
                height: 60,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(height: 16),
              _GameButton(
                label: 'ATTACK',
                icon: Icons.gps_fixed,
                keyDef: LogicalKeyboardKey.keyA,
                controller: widget.keyboardController,
                color: Colors.redAccent,
                width: 120,
                height: 60,
                gradient: LinearGradient(
                  colors: [Colors.redAccent, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GameButton extends StatefulWidget {
  const _GameButton({
    Key? key,
    required this.label,
    this.icon,
    this.keyDef,
    this.controller,
    this.onDown,
    this.onUp,
    this.size,
    this.width,
    this.height,
    this.color,
    this.gradient,
    this.onSystemPointerEvent,
  }) : super(key: key);

  final String label;
  final IconData? icon;
  final LogicalKeyboardKey? keyDef;
  final KeyboardController? controller;
  final VoidCallback? onDown;
  final VoidCallback? onUp;
  final double? size;
  final double? width;
  final double? height;
  final Color? color;
  final Gradient? gradient;
  final void Function(PointerEvent)? onSystemPointerEvent;

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? widget.size ?? 48;
    final h = widget.height ?? widget.size ?? 48;
    final baseColor = widget.color ?? Colors.white;

    return TouchOnlyGestureDetector(
      onSystemPointerEvent: widget.onSystemPointerEvent,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        if (widget.keyDef != null && widget.controller != null) {
          widget.controller!.simulateKey(widget.keyDef!, true);
        }
        widget.onDown?.call();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.keyDef != null && widget.controller != null) {
          widget.controller!.simulateKey(widget.keyDef!, false);
        }
        widget.onUp?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        if (widget.keyDef != null && widget.controller != null) {
          widget.controller!.simulateKey(widget.keyDef!, false);
        }
        widget.onUp?.call();
      },
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: widget.gradient == null
              ? (_isPressed
                  ? baseColor.withOpacity(0.6)
                  : baseColor.withOpacity(0.2))
              : null,
          gradient: widget.gradient?.scale(_isPressed ? 1.2 : 1.0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: baseColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            if (_isPressed || widget.gradient != null)
              BoxShadow(
                color: baseColor.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Center(
          child: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: Colors.white,
                  size: min(w, h) * 0.5,
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: min(w, h) * 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

class _WASDJoystick extends StatefulWidget {
  const _WASDJoystick({
    Key? key,
    required this.onKey,
    this.onSystemPointerEvent,
  }) : super(key: key);

  final void Function(LogicalKeyboardKey, bool) onKey;
  final void Function(PointerEvent)? onSystemPointerEvent;

  @override
  State<_WASDJoystick> createState() => _WASDJoystickState();
}

class _WASDJoystickState extends State<_WASDJoystick> {
  Offset _delta = Offset.zero;
  static const double _radius = 60;
  static const double _stickRadius = 25;

  // Track pressed keys to avoid repeated events
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  void _updateDelta(Offset localPosition) {
    final center = const Offset(_radius, _radius);
    final diff = localPosition - center;
    final dist = diff.distance;

    if (dist <= _radius) {
      _delta = diff;
    } else {
      _delta = Offset.fromDirection(diff.direction, _radius);
    }

    _updateKeys(_delta.dx / _radius, -_delta.dy / _radius);
    setState(() {});
  }

  void _updateKeys(double x, double y) {
    final newKeys = <LogicalKeyboardKey>{};
    const threshold = 0.3;

    if (y > threshold) newKeys.add(LogicalKeyboardKey.keyW);
    if (y < -threshold) newKeys.add(LogicalKeyboardKey.keyS);
    if (x > threshold) newKeys.add(LogicalKeyboardKey.keyD);
    if (x < -threshold) newKeys.add(LogicalKeyboardKey.keyA);

    // Release keys no longer pressed
    for (final key in _pressedKeys) {
      if (!newKeys.contains(key)) {
        widget.onKey(key, false);
      }
    }

    // Press new keys
    for (final key in newKeys) {
      if (!_pressedKeys.contains(key)) {
        widget.onKey(key, true);
      }
    }

    _pressedKeys.clear();
    _pressedKeys.addAll(newKeys);
  }

  void _reset() {
    _delta = Offset.zero;
    for (final key in _pressedKeys) {
      widget.onKey(key, false);
    }
    _pressedKeys.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TouchOnlyGestureDetector(
      onSystemPointerEvent: widget.onSystemPointerEvent,
      onPanStart: (details) => _updateDelta(details.localPosition),
      onPanUpdate: (details) => _updateDelta(details.localPosition),
      onPanEnd: (_) => _reset(),
      child: Container(
        width: _radius * 2,
        height: _radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: Transform.translate(
            offset: _delta,
            child: Container(
              width: _stickRadius * 2,
              height: _stickRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text('WASD',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameTrackpad extends StatelessWidget {
  const _GameTrackpad({
    Key? key,
    required this.mouseController,
    this.onTap,
  }) : super(key: key);

  final MouseController mouseController;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        mouseController.onPointerMove(
          PointerMoveEvent(
            position: details.globalPosition,
            delta: details.delta,
          ),
          const MouseDisplayGeometry.empty(), // We only need relative movement
        );
      },
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Invisible touch area
      ),
    );
  }
}
