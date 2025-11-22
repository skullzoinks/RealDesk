class RealDeskSettings {
  static const List<Map<String, dynamic>> defaultIceServers = [
    {
      'urls': [
        'turn:36.99.188.174:3479?transport=udp',
        'turn:36.99.188.174:3479?transport=tcp',
      ],
      'username': 'yrxt',
      'credential': 'yrxt@unionstech.cn',
    },
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  static const String defaultIceServersJson =
      '[{"urls":["turn:36.99.188.174:3479?transport=udp","turn:36.99.188.174:3479?transport=tcp"],"username":"yrxt","credential":"yrxt@unionstech.cn"},{"urls":"stun:stun.l.google.com:19302"},{"urls":"stun:stun1.l.google.com:19302"}]';

  RealDeskSettings({
    this.insecure = false,
    this.noGoogleStun = false,
    this.overrideIce = false,
    this.iceServersJson = RealDeskSettings.defaultIceServersJson,
    this.heartbeatSeconds = 5,
    this.reconnectDelaySeconds = 3,
    this.maxReconnectAttempts = 3,
    this.defaultShowMetrics = false,
    this.defaultMouseRelative = false,
    this.preferredVideoCodec = 'H264',
    this.enableAudio = true,
    this.audioVolume = 1.0,
    this.useProtobuf = false,
    this.sendLocalMedia = false,
    // Performance settings
    this.enableHardwareAcceleration = true,
    this.videoRenderQuality = VideoRenderQuality.medium,
    // QoS settings
    this.enableQoS = true,
    this.qosHighLossPercentage = 4.0,
    this.qosHighRttMs = 250.0,
    this.qosHighJitterMs = 30.0,
    this.qosBitrateIncreaseStep = 1.10,
    this.qosBitrateDecreaseStep = 0.85,
    this.qosHealthySamplesRequired = 6,
    this.qosMaxBitrate = 4000, // kbps
    this.qosMinBitrate = 500, // kbps
  });

  bool insecure;
  bool noGoogleStun;
  bool overrideIce;
  String iceServersJson; // JSON array string of RTCIceServer objects
  bool enableHardwareAcceleration; // Enable GPU hardware decoding
  VideoRenderQuality videoRenderQuality; // Video rendering quality
  bool enableQoS;
  double qosHighLossPercentage;
  double qosHighRttMs;
  double qosHighJitterMs;
  double qosBitrateIncreaseStep;
  double qosBitrateDecreaseStep;
  int qosHealthySamplesRequired;
  int qosMaxBitrate; // kbps
  int qosMinBitrate; // kbps
  int heartbeatSeconds;
  int reconnectDelaySeconds;
  int maxReconnectAttempts;
  bool defaultShowMetrics;
  bool defaultMouseRelative;
  String preferredVideoCodec;
  bool enableAudio;
  double audioVolume; // 0.0 to 1.0
  bool useProtobuf; // Use Protobuf protocol instead of JSON
  bool sendLocalMedia; // Send local audio/video to remote peer

  Map<String, dynamic> toMap() => {
        'insecure': insecure,
        'noGoogleStun': noGoogleStun,
        'overrideIce': overrideIce,
        'iceServersJson': iceServersJson,
        'heartbeatSeconds': heartbeatSeconds,
        'reconnectDelaySeconds': reconnectDelaySeconds,
        'maxReconnectAttempts': maxReconnectAttempts,
        'defaultShowMetrics': defaultShowMetrics,
        'defaultMouseRelative': defaultMouseRelative,
        'preferredVideoCodec': preferredVideoCodec,
        'enableAudio': enableAudio,
        'audioVolume': audioVolume,
        'useProtobuf': useProtobuf,
        'sendLocalMedia': sendLocalMedia,
        'enableHardwareAcceleration': enableHardwareAcceleration,
        'videoRenderQuality': videoRenderQuality.index,
        'enableQoS': enableQoS,
        'qosHighLossPercentage': qosHighLossPercentage,
        'qosHighRttMs': qosHighRttMs,
        'qosHighJitterMs': qosHighJitterMs,
        'qosBitrateIncreaseStep': qosBitrateIncreaseStep,
        'qosBitrateDecreaseStep': qosBitrateDecreaseStep,
        'qosHealthySamplesRequired': qosHealthySamplesRequired,
        'qosMaxBitrate': qosMaxBitrate,
        'qosMinBitrate': qosMinBitrate,
      };

  static RealDeskSettings fromMap(Map<String, dynamic> m) {
    return RealDeskSettings(
      insecure: m['insecure'] ?? false,
      noGoogleStun: m['noGoogleStun'] ?? false,
      overrideIce: m['overrideIce'] ?? false,
      iceServersJson: (m['iceServersJson'] as String?)?.isNotEmpty == true
          ? m['iceServersJson']
          : RealDeskSettings.defaultIceServersJson,
      heartbeatSeconds: m['heartbeatSeconds'] ?? 5,
      enableQoS: m['enableQoS'] ?? true,
      qosHighLossPercentage:
          (m['qosHighLossPercentage'] as num?)?.toDouble() ?? 4.0,
      qosHighRttMs: (m['qosHighRttMs'] as num?)?.toDouble() ?? 250.0,
      qosHighJitterMs: (m['qosHighJitterMs'] as num?)?.toDouble() ?? 30.0,
      qosBitrateIncreaseStep:
          (m['qosBitrateIncreaseStep'] as num?)?.toDouble() ?? 1.10,
      qosBitrateDecreaseStep:
          (m['qosBitrateDecreaseStep'] as num?)?.toDouble() ?? 0.85,
      qosHealthySamplesRequired: m['qosHealthySamplesRequired'] ?? 6,
      qosMaxBitrate: m['qosMaxBitrate'] ?? 4000,
      qosMinBitrate: m['qosMinBitrate'] ?? 500,
      reconnectDelaySeconds: m['reconnectDelaySeconds'] ?? 3,
      maxReconnectAttempts: m['maxReconnectAttempts'] ?? 3,
      defaultShowMetrics: m['defaultShowMetrics'] ?? false,
      defaultMouseRelative: m['defaultMouseRelative'] ?? false,
      preferredVideoCodec:
          (m['preferredVideoCodec'] as String?)?.toUpperCase() ?? 'H264',
      enableAudio: m['enableAudio'] ?? true,
      audioVolume: (m['audioVolume'] as num?)?.toDouble() ?? 1.0,
      useProtobuf: m['useProtobuf'] ?? false,
      sendLocalMedia: m['sendLocalMedia'] ?? false,
      enableHardwareAcceleration: m['enableHardwareAcceleration'] ?? true,
      videoRenderQuality: VideoRenderQuality.values[
          (m['videoRenderQuality'] as int?) ?? VideoRenderQuality.medium.index],
    );
  }
}

/// Video rendering quality mode
enum VideoRenderQuality {
  /// Low quality - faster rendering, lower CPU usage
  low,

  /// Medium quality - balanced performance
  medium,

  /// High quality - best visual quality, higher CPU usage
  high,
}
