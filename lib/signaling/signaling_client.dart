import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models/signaling_messages.dart';

/// WebSocket-based signaling client
class SignalingClient {
  SignalingClient({
    required this.signalingUrl,
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 3,
  }) : _logger = Logger();

  final String signalingUrl;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;
  final Logger _logger;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  bool _isManualDisconnect = false;
  ConnectionState _state = ConnectionState.disconnected;

  final _stateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ConnectionState> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  ConnectionState get state => _state;

  /// Connect to signaling server
  Future<void> connect() async {
    if (_state == ConnectionState.connected ||
        _state == ConnectionState.connecting) {
      _logger.w('Already connected or connecting');
      return;
    }

    _isManualDisconnect = false;
    _updateState(ConnectionState.connecting);

    try {
      _logger.i('Connecting to signaling server: $signalingUrl');
      _channel = WebSocketChannel.connect(Uri.parse(signalingUrl));

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _updateState(ConnectionState.connected);
      _reconnectAttempts = 0;

      _logger.i('Connected to signaling server');
    } catch (e) {
      _logger.e('Failed to connect: $e');
      _updateState(ConnectionState.failed);
      _scheduleReconnect();
    }
  }

  /// Disconnect from signaling server
  Future<void> disconnect() async {
    _logger.i('Disconnecting from signaling server');
    _isManualDisconnect = true;
    _cancelReconnect();

    await _channel?.sink.close();
    _channel = null;

    _updateState(ConnectionState.disconnected);
  }

  /// Send a message to the signaling server
  void send(Map<String, dynamic> message) {
    if (_state != ConnectionState.connected) {
      _logger.w('Cannot send message: not connected');
      return;
    }

    try {
      final jsonString = jsonEncode(message);
      _channel?.sink.add(jsonString);
      _logger.d('Sent message: $jsonString');
    } catch (e) {
      _logger.e('Failed to send message: $e');
    }
  }

  /// Send register (Ayame)
  void sendRegister({required String roomId, String? clientId, String? key}) {
    final id = clientId ?? DateTime.now().millisecondsSinceEpoch.toString();
    send({
      'type': 'register',
      'clientId': id,
      'roomId': roomId,
      'video': true,
      'audio': true,
      if (key != null) 'key': key,
    });
  }

  /// Send offer
  void sendOffer(String sdp) {
    send({'type': 'offer', 'sdp': sdp});
  }

  /// Send answer
  void sendAnswer(String sdp) {
    send({'type': 'answer', 'sdp': sdp});
  }

  /// Send ICE candidate (Ayame uses { type:'candidate', ice:{...} })
  void sendCandidate(String candidate, String sdpMid, int sdpMLineIndex) {
    send({
      'type': 'candidate',
      'ice': {
        'candidate': candidate,
        'sdpMid': sdpMid,
        'sdpMLineIndex': sdpMLineIndex,
      },
    });
  }

  /// Handle incoming messages
  void _onMessage(dynamic data) {
    try {
      final jsonData = jsonDecode(data as String) as Map<String, dynamic>;
      final type = jsonData['type'] as String?;

      _logger.d('Received message: $type');

      // Heartbeat handling
      if (type == 'ping') {
        // Reply pong to server watchdog
        send({'type': 'pong'});
        return;
      }
      if (type == 'pong') {
        return; // ignore
      }

      _messageController.add(jsonData);
    } catch (e) {
      _logger.e('Failed to parse message: $e');
    }
  }

  /// Handle connection errors
  void _onError(dynamic error) {
    _logger.e('WebSocket error: $error');
    _updateState(ConnectionState.failed);
  }

  /// Handle connection closure
  void _onDone() {
    _logger.i('WebSocket connection closed');

    if (!_isManualDisconnect) {
      _updateState(ConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection
  void _scheduleReconnect() {
    if (_isManualDisconnect || _reconnectAttempts >= maxReconnectAttempts) {
      _logger.w('Max reconnect attempts reached or manual disconnect');
      return;
    }

    _cancelReconnect();
    _reconnectAttempts++;
    _updateState(ConnectionState.reconnecting);

    _logger.i(
      'Scheduling reconnect attempt $_reconnectAttempts/$maxReconnectAttempts',
    );

    _reconnectTimer = Timer(reconnectDelay, () {
      connect();
    });
  }

  /// Cancel reconnection
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Update connection state
  void _updateState(ConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Dispose resources
  void dispose() {
    _cancelReconnect();
    _channel?.sink.close();
    _stateController.close();
    _messageController.close();
  }
}
