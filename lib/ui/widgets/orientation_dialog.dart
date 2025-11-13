import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/orientation_manager.dart';

/// 屏幕方向选择对话框
class OrientationSettingsDialog extends StatefulWidget {
  const OrientationSettingsDialog({Key? key}) : super(key: key);

  @override
  State<OrientationSettingsDialog> createState() =>
      _OrientationSettingsDialogState();
}

class _OrientationSettingsDialogState extends State<OrientationSettingsDialog> {
  String _selectedOption = 'auto';

  final List<Map<String, dynamic>> _orientationOptions = [
    {
      'value': 'auto',
      'title': '自动适应',
      'subtitle': '根据视频尺寸自动调整方向',
      'icon': Icons.auto_awesome_motion,
    },
    {
      'value': 'all',
      'title': '允许所有方向',
      'subtitle': '横屏和竖屏都允许',
      'icon': Icons.screen_rotation,
    },
    {
      'value': 'landscape',
      'title': '锁定横屏',
      'subtitle': '只允许横屏显示',
      'icon': Icons.stay_current_landscape,
    },
    {
      'value': 'portrait',
      'title': '锁定竖屏',
      'subtitle': '只允许竖屏显示',
      'icon': Icons.stay_current_portrait,
    },
    {
      'value': 'landscape_left',
      'title': '横屏向左',
      'subtitle': '锁定为横屏向左',
      'icon': Icons.rotate_left,
    },
    {
      'value': 'landscape_right',
      'title': '横屏向右',
      'subtitle': '锁定为横屏向右',
      'icon': Icons.rotate_right,
    },
    {
      'value': 'portrait_up',
      'title': '竖屏向上',
      'subtitle': '锁定为竖屏向上',
      'icon': Icons.stay_current_portrait,
    },
  ];

  Future<void> _applyOrientation(String option) async {
    try {
      switch (option) {
        case 'all':
          await OrientationManager.instance.allowAllOrientations();
          break;
        case 'landscape':
          await OrientationManager.instance.lockToLandscape();
          break;
        case 'portrait':
          await OrientationManager.instance.lockToPortrait();
          break;
        case 'landscape_left':
          await OrientationManager.instance.lockToLandscapeLeft();
          break;
        case 'landscape_right':
          await OrientationManager.instance.lockToLandscapeRight();
          break;
        case 'portrait_up':
          await OrientationManager.instance.lockToPortraitUp();
          break;
        case 'auto':
        default:
          await OrientationManager.instance.resetToDefault();
          break;
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设置屏幕方向失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.screen_rotation),
          SizedBox(width: 8),
          Text('屏幕方向设置'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _orientationOptions.length,
          itemBuilder: (context, index) {
            final option = _orientationOptions[index];
            return RadioListTile<String>(
              value: option['value'],
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value!;
                });
              },
              title: Row(
                children: [
                  Icon(
                    option['icon'],
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(option['title']),
                ],
              ),
              subtitle: Text(
                option['subtitle'],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => _applyOrientation(_selectedOption),
          child: const Text('应用'),
        ),
      ],
    );
  }
}

/// 显示屏幕方向设置对话框
Future<bool?> showOrientationSettingsDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const OrientationSettingsDialog(),
  );
}

/// 快速屏幕方向切换底部表单
class QuickOrientationSheet extends StatelessWidget {
  const QuickOrientationSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速切换屏幕方向',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickOrientationButton(
                icon: Icons.screen_rotation,
                label: '切换',
                onPressed: () async {
                  await OrientationManager.instance.toggleOrientation();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              _QuickOrientationButton(
                icon: Icons.stay_current_landscape,
                label: '横屏',
                onPressed: () async {
                  await OrientationManager.instance.lockToLandscape();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              _QuickOrientationButton(
                icon: Icons.stay_current_portrait,
                label: '竖屏',
                onPressed: () async {
                  await OrientationManager.instance.lockToPortrait();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              _QuickOrientationButton(
                icon: Icons.auto_awesome_motion,
                label: '自动',
                onPressed: () async {
                  await OrientationManager.instance.allowAllOrientations();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickOrientationButton extends StatelessWidget {
  const _QuickOrientationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// 显示快速屏幕方向切换底部表单
Future<void> showQuickOrientationSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => const QuickOrientationSheet(),
  );
}
