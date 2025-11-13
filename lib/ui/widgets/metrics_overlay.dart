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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getQualityColor(quality),
              width: 2,
            ),
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getQualityText(quality),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.grey),

              // Metrics
              _buildMetricRow('FPS', '${metrics.fps.toStringAsFixed(1)}'),
              _buildMetricRow('视频码率', metrics.videoBitrateFormatted),
              _buildMetricRow('音频码率', metrics.audioBitrateFormatted),
              _buildMetricRow('RTT', '${metrics.rtt} ms'),
              _buildMetricRow(
                'Jitter',
                '${metrics.jitter.toStringAsFixed(2)} ms',
              ),
              _buildMetricRow(
                '丢包率',
                '${metrics.packetLoss.toStringAsFixed(2)}%',
              ),
              _buildMetricRow('已接收帧', '${metrics.framesReceived}'),
              _buildMetricRow('丢失帧', '${metrics.framesDropped}'),
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
        return '优秀';
      case ConnectionQuality.good:
        return '良好';
      case ConnectionQuality.fair:
        return '一般';
      case ConnectionQuality.poor:
        return '较差';
      case ConnectionQuality.bad:
        return '很差';
      case ConnectionQuality.unknown:
        return '未知';
    }
  }
}

