import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

/// 管理应用的音频设置和播放
class AudioManager {
  AudioManager._();
  static final AudioManager _instance = AudioManager._();
  static AudioManager get instance => _instance;

  final Logger _logger = Logger();
  double _volume = 1.0;
  bool _enabled = true;
  bool _muted = false;

  /// 获取当前音量 (0.0 - 1.0)
  double get volume => _volume;

  /// 获取音频是否启用
  bool get enabled => _enabled;

  /// 获取是否静音
  bool get muted => _muted;

  /// 获取实际音量（考虑静音状态）
  double get effectiveVolume => _muted ? 0.0 : _volume;

  /// 设置音量
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      _logger.w('Invalid volume value: $volume. Must be between 0.0 and 1.0');
      return;
    }

    _volume = volume;
    _logger.i('Audio volume set to: ${(_volume * 100).toInt()}%');

    // 如果有活动的音频渲染器，应用音量设置
    await _applyVolumeToActiveRenderers();
  }

  /// 启用或禁用音频
  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;

    _enabled = enabled;
    _logger.i('Audio ${enabled ? 'enabled' : 'disabled'}');

    await _applyVolumeToActiveRenderers();
  }

  /// 切换静音状态
  Future<void> toggleMute() async {
    _muted = !_muted;
    _logger.i('Audio ${_muted ? 'muted' : 'unmuted'}');

    await _applyVolumeToActiveRenderers();
  }

  /// 设置静音状态
  Future<void> setMuted(bool muted) async {
    if (_muted == muted) return;

    _muted = muted;
    _logger.i('Audio ${muted ? 'muted' : 'unmuted'}');

    await _applyVolumeToActiveRenderers();
  }

  /// 增加音量
  Future<void> volumeUp([double step = 0.1]) async {
    await setVolume((_volume + step).clamp(0.0, 1.0));
  }

  /// 减少音量
  Future<void> volumeDown([double step = 0.1]) async {
    await setVolume((_volume - step).clamp(0.0, 1.0));
  }

  /// 应用音量设置到活动的渲染器
  Future<void> _applyVolumeToActiveRenderers() async {
    // 注意：flutter_webrtc 的 RTCVideoRenderer 目前不直接支持音量控制
    // 这里预留接口，未来可能需要使用原生平台代码来实现音量控制
    _logger.d(
        'Applied audio settings - Volume: ${(_volume * 100).toInt()}%, Enabled: $_enabled, Muted: $_muted');
  }

  /// 配置音频轨道的音量（如果支持的话）
  void configureAudioTrack(MediaStreamTrack audioTrack) {
    if (audioTrack.kind != 'audio') return;

    try {
      // 启用或禁用音频轨道
      audioTrack.enabled = _enabled && !_muted;
      _logger.i('Audio track configured: enabled=${audioTrack.enabled}');
    } catch (e) {
      _logger.w('Failed to configure audio track: $e');
    }
  }

  /// 配置媒体流的所有音频轨道
  void configureMediaStream(MediaStream stream) {
    final audioTracks = stream.getAudioTracks();
    for (final track in audioTracks) {
      configureAudioTrack(track);
    }
  }

  /// 获取音频状态描述
  String getAudioStatusDescription() {
    if (!_enabled) return '音频已禁用';
    if (_muted) return '静音';
    return '音量: ${(_volume * 100).toInt()}%';
  }

  /// 从设置中加载音频配置
  void loadFromSettings({bool? enableAudio, double? audioVolume}) {
    if (enableAudio != null) {
      _enabled = enableAudio;
    }
    if (audioVolume != null) {
      _volume = audioVolume.clamp(0.0, 1.0);
    }
    _logger.i(
        'Audio settings loaded: enabled=$_enabled, volume=${(_volume * 100).toInt()}%');
  }

  /// 重置为默认设置
  Future<void> resetToDefault() async {
    _enabled = true;
    _volume = 1.0;
    _muted = false;
    await _applyVolumeToActiveRenderers();
    _logger.i('Audio settings reset to default');
  }
}
