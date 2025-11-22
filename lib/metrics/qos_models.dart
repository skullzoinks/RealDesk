/// Quality of Service metrics
class QoSMetrics {
  const QoSMetrics({
    this.videoBitrate = 0,
    this.audioBitrate = 0,
    this.fps = 0.0,
    this.rtt = 0,
    this.jitter = 0.0,
    this.packetLoss = 0.0,
    this.framesReceived = 0,
    this.framesDropped = 0,
    this.codec = '',
    this.localIceServer = '',
    this.remoteIceServer = '',
  });

  final int videoBitrate; // bps
  final int audioBitrate; // bps
  final double fps;
  final int rtt; // ms
  final double jitter; // ms
  final double packetLoss; // percentage
  final int framesReceived;
  final int framesDropped;
  final String codec;
  final String localIceServer;
  final String remoteIceServer;

  ConnectionQuality get quality {
    if (rtt == 0 && packetLoss == 0.0) {
      return ConnectionQuality.unknown;
    }
    if (rtt < 50 && packetLoss < 0.5) {
      return ConnectionQuality.excellent;
    } else if (rtt < 100 && packetLoss < 2.0) {
      return ConnectionQuality.good;
    } else if (rtt < 200 && packetLoss < 5.0) {
      return ConnectionQuality.fair;
    } else if (rtt < 400) {
      return ConnectionQuality.poor;
    } else {
      return ConnectionQuality.bad;
    }
  }

  String get videoBitrateFormatted => formatBitrate(videoBitrate);
  String get audioBitrateFormatted => formatBitrate(audioBitrate);

  static String formatBitrate(int bps) {
    if (bps >= 1000000) {
      return '${(bps / 1000000).toStringAsFixed(2)} Mbps';
    } else if (bps >= 1000) {
      return '${(bps / 1000).toStringAsFixed(2)} kbps';
    } else {
      return '$bps bps';
    }
  }
}

/// Connection quality enum
enum ConnectionQuality {
  unknown,
  excellent,
  good,
  fair,
  poor,
  bad,
}
