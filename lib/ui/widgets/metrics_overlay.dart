import 'package:flutter/material.dart';

import '../../metrics/qos_models.dart';
import '../../metrics/stats_collector.dart';

/// Metrics overlay widget displaying connection statistics
class MetricsOverlay extends StatelessWidget {
  const MetricsOverlay({
    required this.statsCollector,
    Key? key,
  }) : super(key: key);

  final StatsCollector statsCollector;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QoSMetrics>(
      stream: statsCollector.metricsStream,
      initialData: statsCollector.lastMetrics,
      builder: (context, snapshot) {
        final metrics = snapshot.data ?? const QoSMetrics();
        final quality = metrics.quality;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getQualityColor(quality),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quality indicator
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getQualityColor(quality),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getQualityColor(quality).withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getQualityText(quality).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 12),

              // Metrics
              _buildMetricRow('FPS', '${metrics.fps.toStringAsFixed(1)}'),
              _buildMetricRow('VIDEO', metrics.videoBitrateFormatted),
              _buildMetricRow('AUDIO', metrics.audioBitrateFormatted),
              _buildMetricRow('RTT', '${metrics.rtt} ms'),
              _buildMetricRow(
                'JITTER',
                '${metrics.jitter.toStringAsFixed(2)} ms',
              ),
              _buildMetricRow(
                'LOSS',
                '${metrics.packetLoss.toStringAsFixed(2)}%',
              ),
              _buildMetricRow(
                'CODEC',
                metrics.codec.isNotEmpty ? metrics.codec : 'UNKNOWN',
              ),
              _buildMetricRow(
                'ICE (L)',
                metrics.localIceServer.isNotEmpty
                    ? metrics.localIceServer
                    : 'N/A',
              ),
              _buildMetricRow(
                'ICE (R)',
                metrics.remoteIceServer.isNotEmpty
                    ? metrics.remoteIceServer
                    : 'N/A',
              ),
              _buildMetricRow('RX FRAMES', '${metrics.framesReceived}'),
              _buildMetricRow('DROP FRAMES', '${metrics.framesDropped}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.fair:
        return Colors.orange;
      case ConnectionQuality.poor:
        return Colors.red;
      case ConnectionQuality.bad:
        return Colors.deepOrange;
      case ConnectionQuality.unknown:
        return Colors.grey;
    }
  }

  String _getQualityText(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.bad:
        return 'Bad';
      case ConnectionQuality.unknown:
        return 'Unknown';
    }
  }
}
