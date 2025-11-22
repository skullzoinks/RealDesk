import 'package:flutter/material.dart';

class SystemIconButton extends StatefulWidget {
  const SystemIconButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.color,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? color;

  @override
  State<SystemIconButton> createState() => _SystemIconButtonState();
}

class _SystemIconButtonState extends State<SystemIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = _isHovered || widget.isActive;
    final iconColor = widget.color ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
    final backgroundColor = theme.brightness == Brightness.dark 
        ? const Color(0xFF3D3D3D) 
        : Colors.white;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: isSelected ? theme.colorScheme.primary : iconColor,
                  size: 24,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else
              const SizedBox(height: 24), // Placeholder for text height
          ],
        ),
      ),
    );
  }
}
