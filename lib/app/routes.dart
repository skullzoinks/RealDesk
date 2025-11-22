import 'package:flutter/material.dart';

import '../ui/pages/connect_page.dart';
import '../ui/pages/launch_page.dart';
import '../ui/pages/session_page.dart';
import '../ui/pages/settings_page.dart';

/// Application routes
class AppRoutes {
  static const String launch = '/';
  static const String connect = '/connect';
  static const String session = '/session';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case launch:
        return MaterialPageRoute(builder: (_) => const LaunchPage());

      case connect:
        return MaterialPageRoute(builder: (_) => const ConnectPage());

      case AppRoutes.session:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _errorRoute('缺少连接参数');
        }

        final signalingUrl = args['signalingUrl'] as String?;
        final roomId = args['roomId'] as String?;

        if (signalingUrl == null || roomId == null) {
          return _errorRoute('无效的连接参数');
        }

        return MaterialPageRoute(
          builder: (_) => SessionPage(
            signalingUrl: signalingUrl,
            roomId: roomId,
            token: args['token'] as String?,
          ),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      default:
        return _errorRoute('未找到页面: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('错误')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
