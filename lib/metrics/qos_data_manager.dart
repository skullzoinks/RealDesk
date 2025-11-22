import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

import 'qos_congestion_controller.dart';

/// Message types for QoS data channel communication
enum QoSMessageType {
  metricsUpdate('metrics_update'),
  bitrateCommand('bitrate_command'),
  configUpdate('config_update'),
  statisticsRequest('statistics_request'),
  statisticsResponse('statistics_response');

  const QoSMessageType(this.value);
  final String value;

  static QoSMessageType? fromString(String value) {
    for (final type in QoSMessageType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// QoS message structure
class QoSMessage {
  const QoSMessage({
    required this.type,
    required this.data,
    this.timestamp,
  });

  final QoSMessageType type;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  factory QoSMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = typeStr != null ? QoSMessageType.fromString(typeStr) : null;
    if (type == null) {
      throw ArgumentError('Invalid message type: $typeStr');
    }

    return QoSMessage(
      type: type,
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'data': data,
      'timestamp': timestamp?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory QoSMessage.metricsUpdate(EnhancedQoSMetrics metrics) {
    return QoSMessage(
      type: QoSMessageType.metricsUpdate,
      data: {
        'videoBitrate': metrics.videoBitrate,
        'audioBitrate': metrics.audioBitrate,
        'fps': metrics.fps,
        'rtt': metrics.rtt,
        'jitter': metrics.jitter,
        'packetLoss': metrics.packetLoss,
        'framesReceived': metrics.framesReceived,
        'framesDropped': metrics.framesDropped,
        'decodingTime': metrics.decodingTime,
        'frameWidth': metrics.frameWidth,
        'frameHeight': metrics.frameHeight,
        'isCongested': metrics.isCongested,
        'limitingFactor': metrics.limitingFactor,
        'targetBitrate': metrics.targetBitrate,
        'minBitrate': metrics.minBitrate,
        'maxBitrate': metrics.maxBitrate,
      },
      timestamp: DateTime.now(),
    );
  }

  factory QoSMessage.bitrateCommand(int targetBitrate,
      {int? minBitrate, int? maxBitrate}) {
    return QoSMessage(
      type: QoSMessageType.bitrateCommand,
      data: {
        'targetBitrate': targetBitrate,
        if (minBitrate != null) 'minBitrate': minBitrate,
        if (maxBitrate != null) 'maxBitrate': maxBitrate,
      },
      timestamp: DateTime.now(),
    );
  }

  factory QoSMessage.configUpdate(QoSConfig config) {
    return QoSMessage(
      type: QoSMessageType.configUpdate,
      data: {
        'pollIntervalMs': config.pollIntervalMs,
        'highLossPercentage': config.highLossPercentage,
        'highRttMs': config.highRttMs,
        'highJitterMs': config.highJitterMs,
        'increaseStep': config.increaseStep,
        'decreaseStep': config.decreaseStep,
        'healthySamplesRequired': config.healthySamplesRequired,
        'floorBitrateBps': config.floorBitrateBps,
        'maxBitrateBps': config.maxBitrateBps,
        'minBitrateBps': config.minBitrateBps,
      },
      timestamp: DateTime.now(),
    );
  }

  factory QoSMessage.statisticsRequest() {
    return QoSMessage(
      type: QoSMessageType.statisticsRequest,
      data: {},
      timestamp: DateTime.now(),
    );
  }
}

/// Callback for QoS message handling
typedef QoSMessageCallback = void Function(QoSMessage message);

/// Data channel manager for QoS metrics and remote control
class QoSDataChannelManager {
  QoSDataChannelManager({
    required this.peerConnection,
    this.onMessage,
  }) : _logger = Logger();

  final RTCPeerConnection peerConnection;
  final QoSMessageCallback? onMessage;
  final Logger _logger;

  RTCDataChannel? _dataChannel;
  bool _isConnected = false;

  /// Initialize data channel for QoS communication
  Future<void> initialize() async {
    try {
      // Create data channel for QoS metrics
      _dataChannel = await peerConnection.createDataChannel(
        'qos_metrics',
        RTCDataChannelInit()
          ..ordered = false
          ..maxRetransmits = 0
          ..protocol = 'qos-metrics-v1',
      );

      _setupDataChannelHandlers();
      _logger.i('QoS data channel initialized');
    } catch (e) {
      _logger.e('Failed to initialize QoS data channel: $e');
      rethrow;
    }
  }

  /// Setup data channel event handlers
  void _setupDataChannelHandlers() {
    if (_dataChannel == null) return;

    _dataChannel!.onDataChannelState = (state) {
      _logger.d('QoS data channel state: $state');
      _isConnected = state == RTCDataChannelState.RTCDataChannelOpen;
    };

    _dataChannel!.onMessage = (message) {
      _handleIncomingMessage(message);
    };

    _dataChannel!.onBufferedAmountLow = (int threshold) {
      _logger.d('QoS data channel buffer low, threshold: $threshold');
    };
  }

  /// Handle incoming data channel messages
  void _handleIncomingMessage(RTCDataChannelMessage message) {
    try {
      String messageText;

      if (message.isBinary) {
        messageText = utf8.decode(message.binary);
      } else {
        messageText = message.text;
      }

      final json = jsonDecode(messageText) as Map<String, dynamic>;
      final qosMessage = QoSMessage.fromJson(json);

      _logger.d('Received QoS message: ${qosMessage.type.value}');
      onMessage?.call(qosMessage);
    } catch (e) {
      _logger.w('Failed to parse QoS message: $e');
    }
  }

  /// Send QoS message through data channel
  Future<bool> sendMessage(QoSMessage message) async {
    if (!_isConnected || _dataChannel == null) {
      _logger.w('QoS data channel not connected, cannot send message');
      return false;
    }

    try {
      final messageText = message.toJsonString();
      final messageBytes = Uint8List.fromList(utf8.encode(messageText));

      await _dataChannel!.send(RTCDataChannelMessage.fromBinary(messageBytes));
      return true;
    } catch (e) {
      _logger.e('Failed to send QoS message: $e');
      return false;
    }
  }

  /// Send metrics update
  Future<bool> sendMetricsUpdate(EnhancedQoSMetrics metrics) async {
    return sendMessage(QoSMessage.metricsUpdate(metrics));
  }

  /// Send bitrate command
  Future<bool> sendBitrateCommand(int targetBitrate,
      {int? minBitrate, int? maxBitrate}) async {
    return sendMessage(QoSMessage.bitrateCommand(targetBitrate,
        minBitrate: minBitrate, maxBitrate: maxBitrate));
  }

  /// Send config update
  Future<bool> sendConfigUpdate(QoSConfig config) async {
    return sendMessage(QoSMessage.configUpdate(config));
  }

  /// Request statistics from remote
  Future<bool> requestStatistics() async {
    return sendMessage(QoSMessage.statisticsRequest());
  }

  /// Check if data channel is connected
  bool get isConnected => _isConnected;

  /// Get data channel state
  RTCDataChannelState? get state => _dataChannel?.state;

  /// Close data channel and clean up resources
  void close() {
    _dataChannel?.close();
    _dataChannel = null;

    _isConnected = false;
    _logger.i('QoS data channel closed');
  }
}

/// QoS integration helper for managing congestion control and data channel communication
class QoSIntegrationHelper {
  QoSIntegrationHelper({
    required this.congestionController,
    required this.dataChannelManager,
  }) : _logger = Logger();

  final QoSCongestionController congestionController;
  final QoSDataChannelManager dataChannelManager;
  final Logger _logger;

  /// Start QoS integration
  void start() {
    // Setup data channel message handler for remote commands
    if (dataChannelManager.onMessage == null) {
      _logger.w('No QoS data channel handler registered');
    }

    _logger.i('QoS integration started');
  }

  /// Handle incoming QoS messages
  void handleQoSMessage(QoSMessage message) {
    switch (message.type) {
      case QoSMessageType.bitrateCommand:
        _handleBitrateCommand(message);
        break;
      case QoSMessageType.configUpdate:
        _handleConfigUpdate(message);
        break;
      case QoSMessageType.statisticsRequest:
        _handleStatisticsRequest(message);
        break;
      case QoSMessageType.metricsUpdate:
        _logger.d('Received remote QoS metrics update');
        break;
      case QoSMessageType.statisticsResponse:
        _logger.d('Received QoS statistics response: ${message.data}');
        break;
    }
  }

  /// Handle remote bitrate command
  void _handleBitrateCommand(QoSMessage message) {
    try {
      final targetBitrate = message.data['targetBitrate'] as int?;
      if (targetBitrate != null) {
        congestionController.setTargetBitrate(targetBitrate);
        _logger.i('Applied remote bitrate command: $targetBitrate bps');
      }
    } catch (e) {
      _logger.w('Failed to handle bitrate command: $e');
    }
  }

  /// Handle remote config update
  void _handleConfigUpdate(QoSMessage message) {
    try {
      // Config updates would require recreating the congestion controller
      // This is a simplified implementation
      _logger.i('Received config update (restart required)');
    } catch (e) {
      _logger.w('Failed to handle config update: $e');
    }
  }

  /// Handle statistics request
  void _handleStatisticsRequest(QoSMessage message) {
    try {
      // Send current bitrate configuration as response
      final config = congestionController.bitrateConfig;
      final response = QoSMessage(
        type: QoSMessageType.statisticsResponse,
        data: {
          'currentBitrate': config.current,
          'minBitrate': config.min,
          'maxBitrate': config.max,
        },
        timestamp: DateTime.now(),
      );

      dataChannelManager.sendMessage(response);
      _logger.d('Sent statistics response');
    } catch (e) {
      _logger.w('Failed to handle statistics request: $e');
    }
  }

  /// Forward metrics to data channel
  void forwardMetrics(EnhancedQoSMetrics metrics) {
    dataChannelManager.sendMetricsUpdate(metrics);
  }

  /// Stop QoS integration
  void stop() {
    _logger.i('QoS integration stopped');
  }
}
