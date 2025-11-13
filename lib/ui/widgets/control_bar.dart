import 'package:flutter/material.dart';

import '../../input/schema/input_messages.dart';

/// Control bar widget with connection controls
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 8 : 16,
        vertical: isLandscape ? 6 : 12,
      ),
      child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
    );
  }

  Widget _buildPortraitLayout() {
    return Row(
      children: [
        // Connection status
        _buildConnectionStatus(),
        const Spacer(),
        // Control buttons - 使用Flexible来防止溢出
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildControlButtons(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Connection status (compact)
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),

        // Essential buttons only in landscape
        ..._buildCompactButtons(),

        const Spacer(),

        // Compact disconnect button
        ElevatedButton(
          onPressed: onDisconnect,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: const Size(30, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Icon(Icons.close, size: 14),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isConnected ? '已连接' : '未连接',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildControlButtons() {
    return [
      // Metrics toggle
      IconButton(
        icon: Icon(
          showMetrics ? Icons.analytics : Icons.analytics_outlined,
          color: Colors.white,
        ),
        tooltip: showMetrics ? '隐藏统计' : '显示统计',
        onPressed: onToggleMetrics,
      ),
      const SizedBox(width: 4),

      // Mouse mode toggle
      IconButton(
        icon: Icon(
          mouseMode == MouseMode.absolute ? Icons.touch_app : Icons.mouse,
          color: Colors.white,
        ),
        tooltip: mouseMode == MouseMode.absolute ? '切换到相对模式' : '切换到绝对模式',
        onPressed: onToggleMouseMode,
      ),
      const SizedBox(width: 4),

      // Fullscreen toggle
      IconButton(
        icon: Icon(
          isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.white,
        ),
        tooltip: isFullScreen ? '退出全屏' : '进入全屏',
        onPressed: onToggleFullScreen,
      ),
      const SizedBox(width: 4),

      // Audio toggle
      if (onToggleAudio != null) ...[
        IconButton(
          icon: Icon(
            (audioEnabled ?? true) ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
          ),
          tooltip: (audioEnabled ?? true) ? '关闭音频' : '开启音频',
          onPressed: onToggleAudio,
        ),
        const SizedBox(width: 4),
      ],

      // Screen orientation toggle
      if (onToggleOrientation != null) ...[
        IconButton(
          icon: const Icon(
            Icons.screen_rotation,
            color: Colors.white,
          ),
          tooltip: '切换屏幕方向',
          onPressed: onToggleOrientation,
        ),
        const SizedBox(width: 4),
      ],

      // Screen orientation menu
      if (onOrientationMenu != null) ...[
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: Colors.white,
          ),
          tooltip: '屏幕方向选项',
          onSelected: (value) => onOrientationMenu?.call(),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'menu',
              child: Row(
                children: [
                  Icon(Icons.settings_overscan),
                  SizedBox(width: 8),
                  Text('方向设置'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],

      // Disconnect button
      ElevatedButton.icon(
        icon: const Icon(Icons.close, size: 16),
        label: const Text('断开', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(60, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onDisconnect,
      ),
    ];
  }

  List<Widget> _buildCompactButtons() {
    return [
      // Essential buttons with smaller size for landscape
      IconButton(
        icon: Icon(
          showMetrics ? Icons.analytics : Icons.analytics_outlined,
          color: Colors.white,
          size: 18,
        ),
        tooltip: showMetrics ? '隐藏统计' : '显示统计',
        onPressed: onToggleMetrics,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: const EdgeInsets.all(2),
      ),
      IconButton(
        icon: Icon(
          mouseMode == MouseMode.absolute ? Icons.touch_app : Icons.mouse,
          color: Colors.white,
          size: 18,
        ),
        tooltip: mouseMode == MouseMode.absolute ? '切换到相对模式' : '切换到绝对模式',
        onPressed: onToggleMouseMode,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: const EdgeInsets.all(2),
      ),
      IconButton(
        icon: Icon(
          isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.white,
          size: 18,
        ),
        tooltip: isFullScreen ? '退出全屏' : '进入全屏',
        onPressed: onToggleFullScreen,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: const EdgeInsets.all(2),
      ),
    ];
  }
}
