import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../input/keyboard_controller.dart';

class VirtualKeyboard extends StatelessWidget {
  const VirtualKeyboard({
    Key? key,
    required this.controller,
    required this.onClose,
  }) : super(key: key);

  final KeyboardController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_hide,
                            color: Colors.white70),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  _buildRow([
                    _KeyDef(LogicalKeyboardKey.backquote, '`'),
                    _KeyDef(LogicalKeyboardKey.digit1, '1'),
                    _KeyDef(LogicalKeyboardKey.digit2, '2'),
                    _KeyDef(LogicalKeyboardKey.digit3, '3'),
                    _KeyDef(LogicalKeyboardKey.digit4, '4'),
                    _KeyDef(LogicalKeyboardKey.digit5, '5'),
                    _KeyDef(LogicalKeyboardKey.digit6, '6'),
                    _KeyDef(LogicalKeyboardKey.digit7, '7'),
                    _KeyDef(LogicalKeyboardKey.digit8, '8'),
                    _KeyDef(LogicalKeyboardKey.digit9, '9'),
                    _KeyDef(LogicalKeyboardKey.digit0, '0'),
                    _KeyDef(LogicalKeyboardKey.minus, '-'),
                    _KeyDef(LogicalKeyboardKey.equal, '='),
                    _KeyDef(LogicalKeyboardKey.backspace, 'delete', flex: 1.5),
                  ]),
                  _buildRow([
                    _KeyDef(LogicalKeyboardKey.tab, 'tab', flex: 1.5),
                    _KeyDef(LogicalKeyboardKey.keyQ, 'Q'),
                    _KeyDef(LogicalKeyboardKey.keyW, 'W'),
                    _KeyDef(LogicalKeyboardKey.keyE, 'E'),
                    _KeyDef(LogicalKeyboardKey.keyR, 'R'),
                    _KeyDef(LogicalKeyboardKey.keyT, 'T'),
                    _KeyDef(LogicalKeyboardKey.keyY, 'Y'),
                    _KeyDef(LogicalKeyboardKey.keyU, 'U'),
                    _KeyDef(LogicalKeyboardKey.keyI, 'I'),
                    _KeyDef(LogicalKeyboardKey.keyO, 'O'),
                    _KeyDef(LogicalKeyboardKey.keyP, 'P'),
                    _KeyDef(LogicalKeyboardKey.bracketLeft, '['),
                    _KeyDef(LogicalKeyboardKey.bracketRight, ']'),
                    _KeyDef(LogicalKeyboardKey.backslash, '\\'),
                  ]),
                  _buildRow([
                    _KeyDef(LogicalKeyboardKey.capsLock, 'caps lock',
                        flex: 1.8),
                    _KeyDef(LogicalKeyboardKey.keyA, 'A'),
                    _KeyDef(LogicalKeyboardKey.keyS, 'S'),
                    _KeyDef(LogicalKeyboardKey.keyD, 'D'),
                    _KeyDef(LogicalKeyboardKey.keyF, 'F'),
                    _KeyDef(LogicalKeyboardKey.keyG, 'G'),
                    _KeyDef(LogicalKeyboardKey.keyH, 'H'),
                    _KeyDef(LogicalKeyboardKey.keyJ, 'J'),
                    _KeyDef(LogicalKeyboardKey.keyK, 'K'),
                    _KeyDef(LogicalKeyboardKey.keyL, 'L'),
                    _KeyDef(LogicalKeyboardKey.semicolon, ';'),
                    _KeyDef(LogicalKeyboardKey.quote, '\''),
                    _KeyDef(LogicalKeyboardKey.enter, 'return', flex: 1.8),
                  ]),
                  _buildRow([
                    _KeyDef(LogicalKeyboardKey.shiftLeft, 'shift', flex: 2.4),
                    _KeyDef(LogicalKeyboardKey.keyZ, 'Z'),
                    _KeyDef(LogicalKeyboardKey.keyX, 'X'),
                    _KeyDef(LogicalKeyboardKey.keyC, 'C'),
                    _KeyDef(LogicalKeyboardKey.keyV, 'V'),
                    _KeyDef(LogicalKeyboardKey.keyB, 'B'),
                    _KeyDef(LogicalKeyboardKey.keyN, 'N'),
                    _KeyDef(LogicalKeyboardKey.keyM, 'M'),
                    _KeyDef(LogicalKeyboardKey.comma, ','),
                    _KeyDef(LogicalKeyboardKey.period, '.'),
                    _KeyDef(LogicalKeyboardKey.slash, '/'),
                    _KeyDef(LogicalKeyboardKey.shiftRight, 'shift', flex: 2.4),
                  ]),
                  _buildRow([
                    _KeyDef(LogicalKeyboardKey.fn, 'fn'),
                    _KeyDef(LogicalKeyboardKey.controlLeft, 'control'),
                    _KeyDef(LogicalKeyboardKey.altLeft, 'option'),
                    _KeyDef(LogicalKeyboardKey.metaLeft, 'command', flex: 1.2),
                    _KeyDef(LogicalKeyboardKey.space, '', flex: 5),
                    _KeyDef(LogicalKeyboardKey.metaRight, 'command', flex: 1.2),
                    _KeyDef(LogicalKeyboardKey.altRight, 'option'),
                    _KeyDef(LogicalKeyboardKey.arrowLeft, '◀'),
                    _KeyDef(LogicalKeyboardKey.arrowUp, '▲'),
                    _KeyDef(LogicalKeyboardKey.arrowDown, '▼'),
                    _KeyDef(LogicalKeyboardKey.arrowRight, '▶'),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<_KeyDef> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: keys
            .map((k) => Expanded(
                  flex: (k.flex * 10).toInt(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: _VirtualKey(
                      keyDef: k,
                      controller: controller,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _KeyDef {
  final LogicalKeyboardKey key;
  final String label;
  final double flex;

  _KeyDef(this.key, this.label, {this.flex = 1.0});
}

class _VirtualKey extends StatefulWidget {
  const _VirtualKey({
    Key? key,
    required this.keyDef,
    required this.controller,
  }) : super(key: key);

  final _KeyDef keyDef;
  final KeyboardController controller;

  @override
  State<_VirtualKey> createState() => _VirtualKeyState();
}

class _VirtualKeyState extends State<_VirtualKey> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.controller.simulateKey(widget.keyDef.key, true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.controller.simulateKey(widget.keyDef.key, false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.controller.simulateKey(widget.keyDef.key, false);
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.white.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            widget.keyDef.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
