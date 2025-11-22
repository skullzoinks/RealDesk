import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

import 'qos_models.dart';

/// WebRTC statistics collector
class StatsCollector {
  StatsCollector({
    required this.peerConnection,
    this.collectInterval =
        const Duration(seconds: 2), // Increased from 1s to 2s
  }) : _logger = Logger();

  final RTCPeerConnection peerConnection;
  final Duration collectInterval;
  final Logger _logger;

  Timer? _collectTimer;
  QoSMetrics _lastMetrics = const QoSMetrics();
  final Map<String, _VideoStreamSample> _lastVideoSamples = {};
  final Map<String, _AudioStreamSample> _lastAudioSamples = {};

  final _metricsController = StreamController<QoSMetrics>.broadcast();
  Stream<QoSMetrics> get metricsStream => _metricsController.stream;
  QoSMetrics get lastMetrics => _lastMetrics;

  /// Start collecting statistics
  void start() {
    if (_collectTimer != null) {
      _logger.w('Stats collector already started');
      return;
    }

    _lastVideoSamples.clear();
    _lastAudioSamples.clear();
    _lastMetrics = const QoSMetrics();
    _logger.i('Starting stats collection');
    _collectTimer = Timer.periodic(collectInterval, (_) {
      _collectStats();
    });
  }

  /// Stop collecting statistics
  void stop() {
    _collectTimer?.cancel();
    _collectTimer = null;
    _lastVideoSamples.clear();
    _lastAudioSamples.clear();
    _logger.i('Stopped stats collection');
  }

  /// Collect statistics from peer connection
  Future<void> _collectStats() async {
    try {
      final stats = await peerConnection.getStats();
      final metrics = _parseStats(stats);
      _lastMetrics = metrics;
      _metricsController.add(metrics);
    } catch (e) {
      _logger.e('Failed to collect stats: $e');
    }
  }

  /// Parse raw stats into QoS metrics
  QoSMetrics _parseStats(List<StatsReport> stats) {
    final reportsById = <String, StatsReport>{
      for (final report in stats) report.id: report,
    };

    double fps = 0.0;
    int videoBitrate = 0;
    int audioBitrate = 0;
    int rtt = 0;
    double jitter = 0.0;
    double packetLoss = 0.0;
    int framesReceivedMetric = 0;
    int framesDroppedMetric = 0;
    String videoCodec = '';
    String audioCodec = '';
    String localIceServer = '';
    String remoteIceServer = '';

    double fpsMetricSum = 0.0;
    int fpsMetricCount = 0;
    double frameDiffSum = 0.0;
    double frameTimeSum = 0.0;
    double videoBitrateSum = 0.0;
    double audioBitrateSum = 0.0;
    int totalPacketsLost = 0;
    int totalPackets = 0;
    double maxVideoJitter = 0.0;

    for (final report in stats) {
      final values = report.values;
      final reportType = report.type.toString();

      if (reportType == 'inbound-rtp') {
        final mediaType = (values['mediaType'] ?? values['kind'])?.toString();
        final streamId = report.id;
        if (streamId.isEmpty) {
          continue;
        }

        final currentTimestampMs =
            (report.timestamp as num?)?.toDouble() ?? 0.0;
        final bytesReceived = _parseInt(values['bytesReceived']);

        final codecId = values['codecId']?.toString();
        final StatsReport? codecReport =
            codecId != null ? reportsById[codecId] : null;
        final codecValues = codecReport?.values ?? values;
        final resolvedCodec = _resolveCodecLabel(
          codecValues,
          preferredPayload: codecValues['payloadType'] ?? values['payloadType'],
        );
        if (resolvedCodec.isNotEmpty) {
          if (mediaType == 'video') {
            videoCodec = resolvedCodec;
          } else if (mediaType == 'audio' && videoCodec.isEmpty) {
            audioCodec = resolvedCodec;
          }
        }

        if (mediaType == 'video') {
          final framesReceivedCurrent = _parseInt(values['framesReceived']);
          final framesDroppedCurrent = _parseInt(values['framesDropped']);
          if (framesReceivedCurrent > framesReceivedMetric) {
            framesReceivedMetric = framesReceivedCurrent;
          }
          if (framesDroppedCurrent > framesDroppedMetric) {
            framesDroppedMetric = framesDroppedCurrent;
          }

          final framesPerSecond = _parseDouble(values['framesPerSecond']);
          if (framesPerSecond > 0) {
            fpsMetricSum += framesPerSecond;
            fpsMetricCount++;
          }

          final previous = _lastVideoSamples[streamId];
          final intervalSeconds = previous == null
              ? null
              : _resolveIntervalSeconds(
                  currentTimestampMs,
                  previous.timestampMs,
                );

          if (previous != null &&
              intervalSeconds != null &&
              intervalSeconds > 0) {
            final bytesDiff = bytesReceived - previous.bytesReceived;
            if (bytesDiff >= 0) {
              videoBitrateSum += (bytesDiff * 8) / intervalSeconds;
            }

            if (framesPerSecond <= 0) {
              final framesDiff =
                  framesReceivedCurrent - previous.framesReceived;
              if (framesDiff >= 0) {
                frameDiffSum += framesDiff;
                frameTimeSum += intervalSeconds;
              }
            }
          }

          final jitterMs = _parseDouble(values['jitter']) * 1000;
          if (jitterMs > maxVideoJitter) {
            maxVideoJitter = jitterMs;
          }

          final packetsLost = _parseInt(values['packetsLost']);
          final packetsReceivedCount = _parseInt(values['packetsReceived']);
          totalPacketsLost += packetsLost;
          totalPackets += packetsLost + packetsReceivedCount;

          _lastVideoSamples[streamId] = _VideoStreamSample(
            bytesReceived: bytesReceived,
            framesReceived: framesReceivedCurrent,
            timestampMs: currentTimestampMs,
          );
        } else if (mediaType == 'audio') {
          final previous = _lastAudioSamples[streamId];
          final intervalSeconds = previous == null
              ? null
              : _resolveIntervalSeconds(
                  currentTimestampMs,
                  previous.timestampMs,
                );

          if (previous != null &&
              intervalSeconds != null &&
              intervalSeconds > 0) {
            final bytesDiff = bytesReceived - previous.bytesReceived;
            if (bytesDiff >= 0) {
              audioBitrateSum += (bytesDiff * 8) / intervalSeconds;
            }
          }

          _lastAudioSamples[streamId] = _AudioStreamSample(
            bytesReceived: bytesReceived,
            timestampMs: currentTimestampMs,
          );
        }
      } else if (reportType == 'candidate-pair') {
        final state = values['state'] as String?;
        if (state == 'succeeded') {
          rtt = (_parseDouble(values['currentRoundTripTime']) * 1000).round();

          if (localIceServer.isEmpty) {
            final localCandidateId = values['localCandidateId']?.toString();
            final StatsReport? localCandidate =
                localCandidateId != null ? reportsById[localCandidateId] : null;
            if (localCandidate != null) {
              localIceServer =
                  _formatCandidateDescription(localCandidate.values);
            }
          }

          if (remoteIceServer.isEmpty) {
            final remoteCandidateId = values['remoteCandidateId']?.toString();
            final StatsReport? remoteCandidate = remoteCandidateId != null
                ? reportsById[remoteCandidateId]
                : null;
            if (remoteCandidate != null) {
              remoteIceServer =
                  _formatCandidateDescription(remoteCandidate.values);
            }
          }
        }
      }
    }

    if (fpsMetricCount > 0) {
      fps = fpsMetricSum / fpsMetricCount;
    } else if (frameTimeSum > 0) {
      fps = frameDiffSum / frameTimeSum;
    } else if (_lastMetrics.fps > 0) {
      fps = _lastMetrics.fps;
    }

    if (videoBitrateSum > 0) {
      videoBitrate = videoBitrateSum.round();
    } else if (_lastMetrics.videoBitrate > 0) {
      videoBitrate = _lastMetrics.videoBitrate;
    }

    if (audioBitrateSum > 0) {
      audioBitrate = audioBitrateSum.round();
    } else if (_lastMetrics.audioBitrate > 0) {
      audioBitrate = _lastMetrics.audioBitrate;
    }

    if (maxVideoJitter > 0) {
      jitter = maxVideoJitter;
    }

    if (totalPackets > 0) {
      packetLoss = (totalPacketsLost / totalPackets) * 100;
    }

    String codec = videoCodec.isNotEmpty
        ? videoCodec
        : (audioCodec.isNotEmpty ? audioCodec : '');
    if (codec.isEmpty) {
      codec = _lastMetrics.codec;
    }
    if (localIceServer.isEmpty) {
      localIceServer = _lastMetrics.localIceServer;
    }
    if (remoteIceServer.isEmpty) {
      remoteIceServer = _lastMetrics.remoteIceServer;
    }

    return QoSMetrics(
      fps: fps,
      videoBitrate: videoBitrate,
      audioBitrate: audioBitrate,
      rtt: rtt,
      jitter: jitter,
      packetLoss: packetLoss,
      framesReceived: framesReceivedMetric,
      framesDropped: framesDroppedMetric,
      codec: codec,
      localIceServer: localIceServer,
      remoteIceServer: remoteIceServer,
    );
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convert timestamp delta (which may be reported in ms or µs) to seconds.
  double? _resolveIntervalSeconds(double current, double last) {
    final diff = current - last;
    if (diff <= 0) {
      return null;
    }

    var seconds = diff / 1000.0;
    if (seconds > 5) {
      seconds = diff / 1000000.0;
    }

    return seconds > 0 ? seconds : null;
  }

  /// Dispose resources
  void dispose() {
    stop();
    _metricsController.close();
  }

  String _resolveCodecLabel(Map<dynamic, dynamic>? values,
      {dynamic preferredPayload}) {
    if (values == null) {
      return '';
    }

    final String mime =
        (values['mimeType'] ?? values['codec'] ?? '').toString().trim();
    final String payloadType =
        (preferredPayload ?? values['payloadType'] ?? '').toString().trim();
    final String fmtp =
        (values['sdpFmtpLine'] ?? values['parameters'] ?? '').toString().trim();

    final parts = <String>[];
    if (mime.isNotEmpty) {
      parts.add(mime);
    }
    if (payloadType.isNotEmpty) {
      parts.add('PT:$payloadType');
    }
    if (fmtp.isNotEmpty) {
      parts.add(fmtp);
    }

    return parts.join(' ');
  }

  String _formatCandidateDescription(Map<dynamic, dynamic>? values) {
    if (values == null) {
      return '';
    }

    final address =
        (values['address'] ?? values['ip'] ?? values['addressSource'])
            ?.toString()
            .trim();
    final port = (values['port'] ?? values['portNumber'])?.toString().trim();
    final protocol = values['protocol']?.toString().trim().toUpperCase() ?? '';
    final candidateType =
        values['candidateType']?.toString().trim().toLowerCase() ?? '';

    final buffer = StringBuffer();
    if (address != null && address.isNotEmpty) {
      buffer.write(address);
      if (port != null && port.isNotEmpty) {
        buffer.write(':');
        buffer.write(port);
      }
    }

    final metadata = <String>[];
    if (protocol.isNotEmpty) {
      metadata.add(protocol);
    }
    if (candidateType.isNotEmpty) {
      metadata.add(candidateType);
    }

    if (metadata.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write('(');
      buffer.write(metadata.join(', '));
      buffer.write(')');
    }

    return buffer.toString();
  }
}

class _VideoStreamSample {
  const _VideoStreamSample({
    required this.bytesReceived,
    required this.framesReceived,
    required this.timestampMs,
  });

  final int bytesReceived;
  final int framesReceived;
  final double timestampMs;
}

class _AudioStreamSample {
  const _AudioStreamSample({
    required this.bytesReceived,
    required this.timestampMs,
  });

  final int bytesReceived;
  final double timestampMs;
}
