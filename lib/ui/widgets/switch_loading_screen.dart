import 'package:flutter/material.dart';
import 'dart:math' as math;

class SwitchLoadingScreen extends StatefulWidget {
  const SwitchLoadingScreen({
    Key? key,
    required this.statusMessage,
    this.onCancel,
  }) : super(key: key);

  final String statusMessage;
  final VoidCallback? onCancel;

  @override
  State<SwitchLoadingScreen> createState() => _SwitchLoadingScreenState();
}

class _SwitchLoadingScreenState extends State<SwitchLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Pattern (Optional subtle grid or gradient)
          CustomPaint(
            painter: _BackgroundPatternPainter(),
          ),

          // Center Animation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing Rings
                      _buildRing(0.0),
                      _buildRing(0.5),
                      
                      // Rotating Outer Ring
                      RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE60012).withOpacity(0.3),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Stack(
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: ContainerWithShadow(width: 4, height: 4),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ContainerWithShadow(width: 4, height: 4),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Center Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE60012),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE60012).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.gamepad,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Status Text
                Text(
                  widget.statusMessage.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Roboto', // Or a custom font if available
                  ),
                ),
                const SizedBox(height: 8),
                const _AnimatedEllipsis(),
              ],
            ),
          ),

          // Cancel Button (Bottom Right)
          if (widget.onCancel != null)
            Positioned(
              bottom: 40,
              right: 40,
              child: TextButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, color: Colors.white54),
                label: const Text(
                  'CANCEL',
                  style: TextStyle(
                    color: Colors.white54,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRing(double delay) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final value = (_pulseController.value + delay) % 1.0;
        final scale = 1.0 + (value * 1.5); // Scale from 1x to 2.5x
        final opacity = 1.0 - value; // Fade out

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE60012).withOpacity(opacity * 0.5),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ContainerWithShadow extends StatelessWidget {
  final double width;
  final double height;

  const ContainerWithShadow({Key? key, required this.width, required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFFE60012),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AnimatedEllipsis extends StatefulWidget {
  const _AnimatedEllipsis({Key? key}) : super(key: key);

  @override
  State<_AnimatedEllipsis> createState() => __AnimatedEllipsisState();
}

class __AnimatedEllipsisState extends State<_AnimatedEllipsis>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final count = (_controller.value * 4).floor();
        return Text(
          '.' * count,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 0.5,
          ),
        );
      },
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
