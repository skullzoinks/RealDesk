import 'dart:ui';
import 'package:flutter/material.dart';

class SwitchDropdownMenu extends StatefulWidget {
  const SwitchDropdownMenu({
    Key? key,
    required this.onExitFullScreen,
    required this.onToggleDisplayMode,
    required this.displayModeIcon,
    required this.onToggleXbox,
    required this.onTogglePS4,
    required this.onToggleKeyboard,
    required this.onSelectGameKeyboard,
    this.isXboxActive = false,
    this.isPS4Active = false,
    this.isKeyboardActive = false,
  }) : super(key: key);

  final VoidCallback onExitFullScreen;
  final VoidCallback onToggleDisplayMode;
  final IconData displayModeIcon;
  final VoidCallback onToggleXbox;
  final VoidCallback onTogglePS4;
  final VoidCallback onToggleKeyboard;
  final ValueChanged<String> onSelectGameKeyboard;
  final bool isXboxActive;
  final bool isPS4Active;
  final bool isKeyboardActive;

  @override
  State<SwitchDropdownMenu> createState() => _SwitchDropdownMenuState();
}

class _SwitchDropdownMenuState extends State<SwitchDropdownMenu>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool _showSubmenu = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      _showSubmenu = false; // Reset submenu on toggle
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen)
          FadeTransition(
            opacity: _expandAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D).withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
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
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: _showSubmenu ? _buildSubmenu() : _buildMainMenu(),
                  ),
                ),
              ),
            ),
          ),
        FloatingActionButton(
          onPressed: _toggleMenu,
          backgroundColor: const Color(0xFF2D2D2D).withOpacity(0.9),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuItem(
          icon: Icons.fullscreen_exit,
          label: 'Exit Fullscreen',
          onTap: () {
            _toggleMenu();
            widget.onExitFullScreen();
          },
          color: const Color(0xFFE60012),
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: widget.displayModeIcon,
          label: 'Display Mode',
          onTap: widget.onToggleDisplayMode,
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.gamepad,
          label: 'Xbox Controller',
          isActive: widget.isXboxActive,
          onTap: widget.onToggleXbox,
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.gamepad_outlined,
          label: 'PS4 Controller',
          isActive: widget.isPS4Active,
          onTap: widget.onTogglePS4,
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.keyboard,
          label: 'Keyboard',
          isActive: widget.isKeyboardActive,
          onTap: widget.onToggleKeyboard,
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.sports_esports,
          label: 'Game Keyboard',
          onTap: () => setState(() => _showSubmenu = true),
          hasSubmenu: true,
        ),
      ],
    );
  }

  Widget _buildSubmenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuItem(
          icon: Icons.arrow_back,
          label: 'Back',
          onTap: () => setState(() => _showSubmenu = false),
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.videogame_asset,
          label: 'CS2 Layout',
          onTap: () {
            widget.onSelectGameKeyboard('cs2');
            _toggleMenu();
          },
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.videogame_asset_outlined,
          label: 'LOL Layout',
          onTap: () {
            widget.onSelectGameKeyboard('lol');
            _toggleMenu();
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool hasSubmenu = false,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xFF2DD14B)
                    : (color ?? Colors.white),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF2DD14B)
                        : (color ?? Colors.white),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.check,
                  color: Color(0xFF2DD14B),
                  size: 16,
                )
              else if (hasSubmenu)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }
}
