import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../input/gamepad_controller.dart';
import '../../input/gamepad/gamepad_mappings.dart';

class VirtualPS4Controller extends StatefulWidget {
  const VirtualPS4Controller({
    Key? key,
    required this.controller,
    this.controllerIndex = 0,
  }) : super(key: key);

  final GamepadController controller;
  final int controllerIndex;

  @override
  State<VirtualPS4Controller> createState() => _VirtualPS4ControllerState();
}

class _VirtualPS4ControllerState extends State<VirtualPS4Controller> {
  int _buttonsMask = 0;
  double _lx = 0;
  double _ly = 0;
  double _rx = 0;
  double _ry = 0;
  double _lt = 0;
  double _rt = 0;

  void _updateState() {
    widget.controller.updateGamepadState(
      index: widget.controllerIndex,
      buttonsMask: _buttonsMask,
      lx: _lx,
      ly: _ly,
      rx: _rx,
      ry: _ry,
      lt: _lt,
      rt: _rt,
    );
  }

  void _setButton(int button, bool down) {
    if (down) {
      _buttonsMask |= button;
      HapticFeedback.lightImpact();
    } else {
      _buttonsMask &= ~button;
    }
    _updateState();
  }

  void _setAxis(String axis, double value) {
    switch (axis) {
      case 'lx':
        _lx = value;
        break;
      case 'ly':
        _ly = value;
        break;
      case 'rx':
        _rx = value;
        break;
      case 'ry':
        _ry = value;
        break;
      case 'lt':
        _lt = value;
        break;
      case 'rt':
        _rt = value;
        break;
    }
    _updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left Stick (Lower on PS4)
        Positioned(
          left: 140,
          bottom: 40,
          child: _VirtualJoystick(
            onChange: (x, y) {
              _lx = x;
              _ly = y;
              _updateState();
            },
            onPress: (down) => _setButton(XUsbButtons.leftThumb, down),
          ),
        ),

        // D-Pad (Higher on PS4)
        Positioned(
          left: 40,
          bottom: 100,
          child: _DPad(
            onDown: (btn) => _setButton(btn, true),
            onUp: (btn) => _setButton(btn, false),
          ),
        ),

        // Right Stick (Lower on PS4)
        Positioned(
          right: 140,
          bottom: 40,
          child: _VirtualJoystick(
            onChange: (x, y) {
              _rx = x;
              _ry = y;
              _updateState();
            },
            onPress: (down) => _setButton(XUsbButtons.rightThumb, down),
          ),
        ),

        // Shapes Buttons (Higher on PS4)
        Positioned(
          right: 40,
          bottom: 100,
          child: _ShapeButtons(
            onDown: (btn) => _setButton(btn, true),
            onUp: (btn) => _setButton(btn, false),
          ),
        ),

        // L1 / L2
        Positioned(
          left: 40,
          top: 100,
          child: Column(
            children: [
              _TriggerButton(
                label: 'L2',
                onChanged: (val) => _setAxis('lt', val),
              ),
              const SizedBox(height: 16),
              _BumperButton(
                label: 'L1',
                onDown: () => _setButton(XUsbButtons.leftShoulder, true),
                onUp: () => _setButton(XUsbButtons.leftShoulder, false),
              ),
            ],
          ),
        ),

        // R1 / R2
        Positioned(
          right: 40,
          top: 100,
          child: Column(
            children: [
              _TriggerButton(
                label: 'R2',
                onChanged: (val) => _setAxis('rt', val),
              ),
              const SizedBox(height: 16),
              _BumperButton(
                label: 'R1',
                onDown: () => _setButton(XUsbButtons.rightShoulder, true),
                onUp: () => _setButton(XUsbButtons.rightShoulder, false),
              ),
            ],
          ),
        ),

        // Center Buttons (Share, PS, Options)
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CenterButton(
                label: 'SHARE',
                onDown: () => _setButton(XUsbButtons.back, true),
                onUp: () => _setButton(XUsbButtons.back, false),
              ),
              const SizedBox(width: 32),
              _CenterButton(
                icon: Icons.videogame_asset, // PS Button
                onDown: () => _setButton(XUsbButtons.guide, true),
                onUp: () => _setButton(XUsbButtons.guide, false),
                size: 48,
              ),
              const SizedBox(width: 32),
              _CenterButton(
                label: 'OPTIONS',
                onDown: () => _setButton(XUsbButtons.start, true),
                onUp: () => _setButton(XUsbButtons.start, false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VirtualJoystick extends StatefulWidget {
  const _VirtualJoystick({
    Key? key,
    required this.onChange,
    required this.onPress,
  }) : super(key: key);

  final void Function(double x, double y) onChange;
  final void Function(bool down) onPress;

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  Offset _delta = Offset.zero;
  static const double _radius = 60;
  static const double _stickRadius = 25;

  void _updateDelta(Offset localPosition) {
    final center = const Offset(_radius, _radius);
    final diff = localPosition - center;
    final dist = diff.distance;

    if (dist <= _radius) {
      _delta = diff;
    } else {
      _delta = Offset.fromDirection(diff.direction, _radius);
    }

    final x = _delta.dx / _radius;
    final y = -_delta.dy / _radius;
    widget.onChange(x, y);
    setState(() {});
  }

  void _reset() {
    _delta = Offset.zero;
    widget.onChange(0, 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _updateDelta(details.localPosition),
      onPanUpdate: (details) => _updateDelta(details.localPosition),
      onPanEnd: (_) => _reset(),
      onTapDown: (_) {
        widget.onPress(true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => widget.onPress(false),
      onTapCancel: () => widget.onPress(false),
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
                color: const Color(0xFF444444).withOpacity(0.8), // Darker stick
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
                border: Border.all(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  const _DPad({
    Key? key,
    required this.onDown,
    required this.onUp,
  }) : super(key: key);

  final void Function(int) onDown;
  final void Function(int) onUp;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _DPadButton(
              icon: Icons.arrow_drop_up,
              onDown: () => onDown(XUsbButtons.dpadUp),
              onUp: () => onUp(XUsbButtons.dpadUp),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _DPadButton(
              icon: Icons.arrow_drop_down,
              onDown: () => onDown(XUsbButtons.dpadDown),
              onUp: () => onUp(XUsbButtons.dpadDown),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _DPadButton(
              icon: Icons.arrow_left,
              onDown: () => onDown(XUsbButtons.dpadLeft),
              onUp: () => onUp(XUsbButtons.dpadLeft),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _DPadButton(
              icon: Icons.arrow_right,
              onDown: () => onDown(XUsbButtons.dpadRight),
              onUp: () => onUp(XUsbButtons.dpadRight),
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadButton extends StatefulWidget {
  const _DPadButton({
    Key? key,
    required this.icon,
    required this.onDown,
    required this.onUp,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  State<_DPadButton> createState() => _DPadButtonState();
}

class _DPadButtonState extends State<_DPadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onUp();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4), // Sharper corners for PS4
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(widget.icon, color: Colors.white),
      ),
    );
  }
}

class _ShapeButtons extends StatelessWidget {
  const _ShapeButtons({
    Key? key,
    required this.onDown,
    required this.onUp,
  }) : super(key: key);

  final void Function(int) onDown;
  final void Function(int) onUp;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: _ShapeButton(
              icon: Icons.close, // Cross (A)
              color: const Color(0xFF8DA5CE), // PS Blue-ish
              onDown: () => onDown(XUsbButtons.a),
              onUp: () => onUp(XUsbButtons.a),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _ShapeButton(
              icon: Icons.circle_outlined, // Circle (B)
              color: const Color(0xFFFF6B6B), // PS Red-ish
              onDown: () => onDown(XUsbButtons.b),
              onUp: () => onUp(XUsbButtons.b),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _ShapeButton(
              icon: Icons.crop_square, // Square (X)
              color: const Color(0xFFEFA3C8), // PS Pink-ish
              onDown: () => onDown(XUsbButtons.x),
              onUp: () => onUp(XUsbButtons.x),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _ShapeButton(
              icon: Icons.change_history, // Triangle (Y)
              color: const Color(0xFF81C784), // PS Green-ish
              onDown: () => onDown(XUsbButtons.y),
              onUp: () => onUp(XUsbButtons.y),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeButton extends StatefulWidget {
  const _ShapeButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.onDown,
    required this.onUp,
  }) : super(key: key);

  final IconData icon;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  State<_ShapeButton> createState() => _ShapeButtonState();
}

class _ShapeButtonState extends State<_ShapeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onUp();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed
              ? widget.color.withOpacity(0.6)
              : Colors.black.withOpacity(0.3),
          border: Border.all(
            color: widget.color.withOpacity(0.8),
            width: 2,
          ),
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 28,
        ),
      ),
    );
  }
}

class _BumperButton extends StatefulWidget {
  const _BumperButton({
    Key? key,
    required this.label,
    required this.onDown,
    required this.onUp,
  }) : super(key: key);

  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  State<_BumperButton> createState() => _BumperButtonState();
}

class _BumperButtonState extends State<_BumperButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onUp();
      },
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _TriggerButton extends StatefulWidget {
  const _TriggerButton({
    Key? key,
    required this.label,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final ValueChanged<double> onChanged;

  @override
  State<_TriggerButton> createState() => _TriggerButtonState();
}

class _TriggerButtonState extends State<_TriggerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onChanged(1.0);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onChanged(0.0);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onChanged(0.0);
      },
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatefulWidget {
  const _CenterButton({
    Key? key,
    this.icon,
    this.label,
    required this.onDown,
    required this.onUp,
    this.size = 32,
  }) : super(key: key);

  final IconData? icon;
  final String? label;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final double size;

  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onUp();
      },
      child: Container(
        width: widget.label != null ? 80 : widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: widget.label != null ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: widget.label != null ? BorderRadius.circular(16) : null,
          color: _isPressed
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.size * 0.6,
                )
              : Text(
                  widget.label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
