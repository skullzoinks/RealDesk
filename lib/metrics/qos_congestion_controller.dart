import 'dart:async';
import 'dart:math';

import 'package:logger/logger.dart';

import 'qos_models.dart';
import 'stats_collector.dart';

/// Enhanced QoS metrics with congestion detection
class EnhancedQoSMetrics extends QoSMetrics {
  const EnhancedQoSMetrics({
    super.videoBitrate,
    super.audioBitrate,
    super.fps,
    super.rtt,
    super.jitter,
    super.packetLoss,
    super.framesReceived,
    super.framesDropped,
    super.codec,
    super.localIceServer,
    super.remoteIceServer,
    this.decodingTime = 0.0,
    this.frameWidth = 0,
    this.frameHeight = 0,
    this.isCongested = false,
    this.limitingFactor = '',
    this.targetBitrate = 0,
    this.minBitrate = 0,
    this.maxBitrate = 0,
  });

  final double decodingTime; // ms per frame
  final int frameWidth;
  final int frameHeight;
  final bool isCongested;
  final String limitingFactor; // 'loss', 'rtt', 'jitter', or ''
  final int targetBitrate; // Current target bitrate (bps)
  final int minBitrate; // Current min bitrate (bps)
  final int maxBitrate; // Current max bitrate (bps)

  EnhancedQoSMetrics copyWith({
    int? videoBitrate,
    int? audioBitrate,
    double? fps,
    int? rtt,
    double? jitter,
    double? packetLoss,
    int? framesReceived,
    int? framesDropped,
    String? codec,
    String? localIceServer,
    String? remoteIceServer,
    double? decodingTime,
    int? frameWidth,
    int? frameHeight,
    bool? isCongested,
    String? limitingFactor,
    int? targetBitrate,
    int? minBitrate,
    int? maxBitrate,
  }) {
    return EnhancedQoSMetrics(
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      fps: fps ?? this.fps,
      rtt: rtt ?? this.rtt,
      jitter: jitter ?? this.jitter,
      packetLoss: packetLoss ?? this.packetLoss,
      framesReceived: framesReceived ?? this.framesReceived,
      framesDropped: framesDropped ?? this.framesDropped,
      codec: codec ?? this.codec,
      localIceServer: localIceServer ?? this.localIceServer,
      remoteIceServer: remoteIceServer ?? this.remoteIceServer,
      decodingTime: decodingTime ?? this.decodingTime,
      frameWidth: frameWidth ?? this.frameWidth,
      frameHeight: frameHeight ?? this.frameHeight,
      isCongested: isCongested ?? this.isCongested,
      limitingFactor: limitingFactor ?? this.limitingFactor,
      targetBitrate: targetBitrate ?? this.targetBitrate,
      minBitrate: minBitrate ?? this.minBitrate,
      maxBitrate: maxBitrate ?? this.maxBitrate,
    );
  }
}

/// Configuration for QoS congestion controller
class QoSConfig {
  const QoSConfig({
    this.pollIntervalMs = 1000,
    this.highLossPercentage = 4.0,
    this.highRttMs = 250.0,
    this.highJitterMs = 30.0,
    this.increaseStep = 1.10,
    this.decreaseStep = 0.85,
    this.healthySamplesRequired = 6,
    this.floorBitrateBps = 300000, // 300 kbps minimum
    this.maxBitrateBps = 4000000, // 4 Mbps maximum
    this.minBitrateBps = 500000, // 500 kbps minimum
  });

  final int pollIntervalMs;
  final double highLossPercentage;
  final double highRttMs;
  final double highJitterMs;
  final double increaseStep;
  final double decreaseStep;
  final int healthySamplesRequired;
  final int floorBitrateBps;
  final int maxBitrateBps;
  final int minBitrateBps;
}

/// Callback for bitrate adjustment
typedef BitrateAdjustmentCallback = void Function(
    int minBitrate, int maxBitrate);

/// Callback for QoS metrics updates
typedef QoSMetricsCallback = void Function(EnhancedQoSMetrics metrics);

/// QoS congestion controller implementing adaptive bitrate based on network conditions
class QoSCongestionController {
  QoSCongestionController({
    required this.statsCollector,
    required this.config,
    this.onBitrateAdjustment,
    this.onMetricsUpdate,
  }) : _logger = Logger();

  final StatsCollector statsCollector;
  final QoSConfig config;
  final BitrateAdjustmentCallback? onBitrateAdjustment;
  final QoSMetricsCallback? onMetricsUpdate;
  final Logger _logger;

  StreamSubscription<QoSMetrics>? _metricsSubscription;
  bool _running = false;
  int _healthyCounter = 0;
  late int _currentTargetBps;
  late int _configuredMaxBps;
  late int _configuredMinBps;

  /// Start the QoS controller
  void start() {
    if (_running) return;

    _running = true;
    _initializeBitrateConfig();

    _metricsSubscription =
        statsCollector.metricsStream.listen(_processMetrics, onError: (error) {
      _logger.w('Metrics stream error: $error');
    });

    // Process current snapshot immediately to avoid waiting for next tick
    _processMetrics(statsCollector.lastMetrics);
    _logger.i('QoS Congestion Controller started');
  }

  /// Stop the QoS controller
  void stop() {
    if (!_running) return;

    _running = false;
    _metricsSubscription?.cancel();
    _metricsSubscription = null;
    _logger.i('QoS Congestion Controller stopped');
  }

  /// Initialize bitrate configuration
  void _initializeBitrateConfig() {
    _configuredMaxBps = config.maxBitrateBps;
    _configuredMinBps = max(config.minBitrateBps, config.floorBitrateBps);

    if (_configuredMinBps > _configuredMaxBps) {
      final temp = _configuredMinBps;
      _configuredMinBps = _configuredMaxBps;
      _configuredMaxBps = temp;
    }

    _currentTargetBps = _configuredMaxBps;
    _logger.d(
        'Initialized bitrate config: min=${_configuredMinBps}, max=${_configuredMaxBps}, target=${_currentTargetBps}');
  }

  /// Process QoS metrics and apply congestion control
  void _processMetrics(QoSMetrics metrics) {
    if (!_running) return;

    // Create enhanced metrics with congestion detection
    final enhancedMetrics = _createEnhancedMetrics(metrics);
    final updatedMetrics = _evaluateAndApply(enhancedMetrics);
    onMetricsUpdate?.call(updatedMetrics);
  }

  /// Create enhanced metrics from basic QoS metrics
  EnhancedQoSMetrics _createEnhancedMetrics(QoSMetrics metrics) {
    return EnhancedQoSMetrics(
      videoBitrate: metrics.videoBitrate,
      audioBitrate: metrics.audioBitrate,
      fps: metrics.fps,
      rtt: metrics.rtt,
      jitter: metrics.jitter,
      packetLoss: metrics.packetLoss,
      framesReceived: metrics.framesReceived,
      framesDropped: metrics.framesDropped,
      targetBitrate: _currentTargetBps,
      minBitrate: _configuredMinBps,
      maxBitrate: _configuredMaxBps,
    );
  }

  /// Evaluate network conditions and apply bitrate adjustments
  EnhancedQoSMetrics _evaluateAndApply(EnhancedQoSMetrics metrics) {
    bool congested = false;
    String limitingFactor = '';

    // Check for congestion indicators
    if (metrics.packetLoss >= config.highLossPercentage) {
      congested = true;
      limitingFactor = 'loss';
    } else if (metrics.rtt >= config.highRttMs) {
      congested = true;
      limitingFactor = 'rtt';
    } else if (metrics.jitter >= config.highJitterMs) {
      congested = true;
      limitingFactor = 'jitter';
    }

    final updatedMetrics = metrics.copyWith(
      isCongested: congested,
      limitingFactor: limitingFactor,
    );

    if (congested) {
      _handleCongestion(limitingFactor);
    } else {
      _handleHealthyConditions();
    }

    return updatedMetrics.copyWith(
      targetBitrate: _currentTargetBps,
      minBitrate: _configuredMinBps,
      maxBitrate: _configuredMaxBps,
    );
  }

  /// Handle congested network conditions
  void _handleCongestion(String reason) {
    _healthyCounter = 0;

    final newTarget = (_currentTargetBps * config.decreaseStep).round();
    final clampedTarget =
        newTarget.clamp(config.floorBitrateBps, _configuredMaxBps);

    if (clampedTarget < _currentTargetBps) {
      _currentTargetBps = clampedTarget;
      final minBitrate = (_currentTargetBps / 2)
          .round()
          .clamp(config.floorBitrateBps, _currentTargetBps);

      _logger.i(
          'Network congestion detected ($reason), reducing bitrate to ${_currentTargetBps} bps');
      onBitrateAdjustment?.call(minBitrate, _currentTargetBps);
    }
  }

  /// Handle healthy network conditions
  void _handleHealthyConditions() {
    _healthyCounter++;

    if (_healthyCounter >= config.healthySamplesRequired) {
      _healthyCounter = 0;

      final newTarget = (_currentTargetBps * config.increaseStep).round();
      final clampedTarget =
          newTarget.clamp(_configuredMinBps, _configuredMaxBps);

      if (clampedTarget > _currentTargetBps) {
        _currentTargetBps = clampedTarget;
        final minBitrate = (_currentTargetBps / 2)
            .round()
            .clamp(config.floorBitrateBps, _currentTargetBps);

        _logger.i(
            'Network conditions improved, increasing bitrate to ${_currentTargetBps} bps');
        onBitrateAdjustment?.call(minBitrate, _currentTargetBps);
      }
    }
  }

  /// Manually set target bitrate (for remote control)
  void setTargetBitrate(int targetBps) {
    final clampedTarget =
        targetBps.clamp(config.floorBitrateBps, _configuredMaxBps);
    _currentTargetBps = clampedTarget;

    final minBitrate = (_currentTargetBps / 2)
        .round()
        .clamp(config.floorBitrateBps, _currentTargetBps);

    _logger.i('Manual bitrate adjustment to ${_currentTargetBps} bps');
    onBitrateAdjustment?.call(minBitrate, _currentTargetBps);
  }

  /// Get current bitrate configuration
  ({int current, int min, int max}) get bitrateConfig => (
        current: _currentTargetBps,
        min: _configuredMinBps,
        max: _configuredMaxBps
      );
}
