import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/routes.dart';

class SwitchSplashScreen extends StatefulWidget {
  const SwitchSplashScreen({Key? key}) : super(key: key);

  @override
  State<SwitchSplashScreen> createState() => _SwitchSplashScreenState();
}

class _SwitchSplashScreenState extends State<SwitchSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _leftJoyConSlide;
  late Animation<double> _rightJoyConSlide;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Joy-Cons sliding into place
    _leftJoyConSlide = Tween<double>(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _rightJoyConSlide = Tween<double>(begin: 200.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Snap effect (scale bump)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Fade out
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    // Text fade in
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.connect);
    });

    // Play haptic feedback at snap time
    Future.delayed(const Duration(milliseconds: 1000), () {
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE60012), // Nintendo Red
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left Joy-Con Shape
                        Transform.translate(
                          offset: Offset(0, _leftJoyConSlide.value),
                          child: Container(
                            width: 60,
                            height: 140,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE60012),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right Joy-Con Shape
                        Transform.translate(
                          offset: Offset(0, _rightJoyConSlide.value),
                          child: Container(
                            width: 60,
                            height: 140,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE60012),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: const Text(
                        'KLEINVERSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          fontFamily: 'Roboto', // Or system default
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
