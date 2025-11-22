import 'package:flutter/material.dart';

import '../../input/schema/input_messages.dart';

/// Control bar widget with connection controls, styled like a Switch Quick Menu
class ControlBar extends StatelessWidget {
  const ControlBar({
    required this.isConnected,
    required this.showMetrics,
    required this.mouseMode,
    required this.onToggleMetrics,
    required this.onToggleMouseMode,
    required this.onDisconnect,
    required this.onToggleFullScreen,
    required this.isFullScreen,
    this.onToggleOrientation,
    this.onOrientationMenu,
    this.onToggleAudio,
    this.audioEnabled,
    Key? key,
  }) : super(key: key);

  final bool isConnected;
  final bool showMetrics;
  final MouseMode mouseMode;
  final VoidCallback onToggleMetrics;
  final VoidCallback onToggleMouseMode;
  final VoidCallback onDisconnect;
  final VoidCallback onToggleFullScreen;
  final bool isFullScreen;
  final VoidCallback? onToggleOrientation;
  final VoidCallback? onOrientationMenu;
  final VoidCallback? onToggleAudio;
  final bool? audioEnabled;

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final theme = Theme.of(context);

    // Wrap entire control bar in RepaintBoundary to isolate from video rendering
    return RepaintBoundary(
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D).withOpacity(0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Connection Status Indicator
              _buildStatusIndicator(),
              
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 16),

              // Controls
              _buildControlButton(
                icon: showMetrics ? Icons.analytics : Icons.analytics_outlined,
                tooltip: showMetrics ? 'Hide Metrics' : 'Show Metrics',
                isActive: showMetrics,
                onTap: onToggleMetrics,
              ),
              const SizedBox(width: 12),
              
              _buildControlButton(
                icon: mouseMode == MouseMode.absolute ? Icons.touch_app : Icons.mouse,
                tooltip: mouseMode == MouseMode.absolute ? 'Switch to Relative' : 'Switch to Absolute',
                isActive: mouseMode == MouseMode.relative,
                onTap: onToggleMouseMode,
              ),
              const SizedBox(width: 12),

              _buildControlButton(
                icon: isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                tooltip: isFullScreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
                isActive: isFullScreen,
                onTap: onToggleFullScreen,
              ),
              
              if (onToggleAudio != null) ...[
                const SizedBox(width: 12),
                _buildControlButton(
                  icon: (audioEnabled ?? true) ? Icons.volume_up : Icons.volume_off,
                  tooltip: (audioEnabled ?? true) ? 'Mute Audio' : 'Unmute Audio',
                  isActive: audioEnabled ?? true,
                  onTap: onToggleAudio!,
                ),
              ],

              if (onToggleOrientation != null) ...[
                const SizedBox(width: 12),
                _buildControlButton(
                  icon: Icons.screen_rotation,
                  tooltip: 'Rotate Screen',
                  onTap: onToggleOrientation!,
                ),
              ],

              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 16),

              // Disconnect Button
              _buildDisconnectButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFF2DD14B).withOpacity(0.2) : const Color(0xFFE60012).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? const Color(0xFF2DD14B) : const Color(0xFFE60012),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF2DD14B) : const Color(0xFFE60012),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: isConnected ? const Color(0xFF2DD14B) : const Color(0xFFE60012),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDisconnect,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE60012),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE60012).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.power_settings_new, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'EXIT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

