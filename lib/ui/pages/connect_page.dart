import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../app/routes.dart';

/// Connection configuration page styled as a Switch system app
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
          if (mounted) {
            setState(() {
              _isConnecting = false;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Controllers & Sensors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.cardTheme.color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.desktop_windows,
                  size: 50,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 40),
              
              // Form Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Remote Connection',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: _signalingUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Signaling Server',
                            prefixIcon: Icon(Icons.dns),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        TextFormField(
                          controller: _roomIdController,
                          decoration: const InputDecoration(
                            labelText: 'Room ID',
                            prefixIcon: Icon(Icons.meeting_room),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        TextFormField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                            labelText: 'Token (Optional)',
                            prefixIcon: Icon(Icons.key),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 40),
                        
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isConnecting ? null : _connect,
                            child: _isConnecting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
