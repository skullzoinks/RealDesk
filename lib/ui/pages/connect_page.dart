import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../app/routes.dart';

/// Connection configuration page
class ConnectPage extends StatefulWidget {
  const ConnectPage({Key? key}) : super(key: key);

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _signalingUrlController = TextEditingController(
    text: 'ws://36.99.188.174:3000/signaling',
  );
  final _roomIdController = TextEditingController(text: 'test-room');
  final _tokenController = TextEditingController();

  bool _isConnecting = false;

  @override
  void dispose() {
    _signalingUrlController.dispose();
    _roomIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _connect() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    final signalingUrl = _signalingUrlController.text.trim();
    final roomId = _roomIdController.text.trim();
    final token = _tokenController.text.trim();

    _logger.i('Connecting to room: $roomId');

    // Navigate to session page with connection parameters
    Navigator.of(context)
        .pushNamed(
          '/session',
          arguments: {
            'signalingUrl': signalingUrl,
            'roomId': roomId,
            'token': token.isEmpty ? null : token,
          },
        )
        .then((_) {
          setState(() {
            _isConnecting = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RealDesk Remote Control'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or icon
                  const Icon(
                    Icons.desktop_windows,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    '连接到远程桌面',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Signaling URL input
                  TextFormField(
                    controller: _signalingUrlController,
                    decoration: const InputDecoration(
                      labelText: '信令服务器地址',
                      hintText: 'ws://example.com:3000/signaling',
                      prefixIcon: Icon(Icons.dns),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入信令服务器地址';
                      }
                      if (!value.startsWith('ws://') &&
                          !value.startsWith('wss://')) {
                        return '地址必须以 ws:// 或 wss:// 开头';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Room ID input
                  TextFormField(
                    controller: _roomIdController,
                    decoration: const InputDecoration(
                      labelText: '房间 ID',
                      hintText: '输入房间标识符',
                      prefixIcon: Icon(Icons.meeting_room),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入房间 ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Token input (optional)
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: '访问令牌（可选）',
                      hintText: '如果需要，请输入访问令牌',
                      prefixIcon: Icon(Icons.key),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),

                  // Connect button
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isConnecting
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('连接', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),

                  // Help text
                  Text(
                    '提示：确保远程主机正在运行并且网络连接正常',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
