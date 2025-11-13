import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

/// Central place to manage remote audio state (volume/mute/platform routing).
class AudioManager {
  AudioManager._();

  static final AudioManager _instance = AudioManager._();
  static AudioManager get instance => _instance;

  final Logger _logger = Logger();

  double _volume = 1.0;
  bool _enabled = true;
  bool _muted = false;
  bool _audioSessionConfigured = false;

  final Map<String, MediaStreamTrack> _trackedAudioTracks = {};

  /// Current logical volume (0.0 - 1.0).
  double get volume => _volume;

  /// Whether audio output is allowed.
  bool get enabled => _enabled;

  /// Whether audio is muted.
  bool get muted => _muted;

  /// Effective volume after mute has been applied.
  double get effectiveVolume => _muted ? 0.0 : _volume;

  /// Set the preferred output volume (0.0 - 1.0).
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      _logger.w('Invalid volume value: $volume. Must be between 0.0 and 1.0');
      return;
    }
    _volume = volume;
    _logger.i('Audio volume set to: ${(_volume * 100).toInt()}%');
    await _applyVolumeToActiveRenderers();
  }

  /// Enable or disable audio completely.
  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    _logger.i('Audio ${enabled ? 'enabled' : 'disabled'}');
    await _applyVolumeToActiveRenderers();
  }

  /// Toggle mute state.
  Future<void> toggleMute() async {
    _muted = !_muted;
    _logger.i('Audio ${_muted ? 'muted' : 'unmuted'}');
    await _applyVolumeToActiveRenderers();
  }

  /// Explicitly set mute state.
  Future<void> setMuted(bool muted) async {
    if (_muted == muted) return;
    _muted = muted;
    _logger.i('Audio ${muted ? 'muted' : 'unmuted'}');
    await _applyVolumeToActiveRenderers();
  }

  /// Increase volume by [step].
  Future<void> volumeUp([double step = 0.1]) async {
    await setVolume((_volume + step).clamp(0.0, 1.0));
  }

  /// Decrease volume by [step].
  Future<void> volumeDown([double step = 0.1]) async {
    await setVolume((_volume - step).clamp(0.0, 1.0));
  }

  /// Register and configure every audio track contained in [stream].
  Future<void> configureMediaStream(MediaStream stream) async {
    final audioTracks = stream.getAudioTracks();
    if (audioTracks.isEmpty) {
      _logger.w('Media stream ${stream.id} does not contain audio tracks');
      return;
    }

    for (final track in audioTracks) {
      await configureAudioTrack(track);
    }
  }

  /// Configure a single audio track (volume + enabled flag).
  Future<void> configureAudioTrack(MediaStreamTrack audioTrack) async {
    if (audioTrack.kind != 'audio') return;

    final trackKey = _trackKey(audioTrack);
    _trackedAudioTracks[trackKey] = audioTrack;
    audioTrack.onEnded = () {
      _trackedAudioTracks.remove(trackKey);
    };

    try {
      await _ensurePlatformAudioSession();
      await _applySettingsToTrack(audioTrack);
    } catch (e) {
      _logger.w('Failed to configure audio track ${trackKey}: $e');
    }
  }

  /// Remove all tracks that belong to [stream] from the registry.
  void unregisterMediaStream(MediaStream? stream) {
    if (stream == null) return;
    for (final track in stream.getAudioTracks()) {
      _trackedAudioTracks.remove(_trackKey(track));
    }
  }

  /// Human readable audio state for snackbars/overlays.
  String getAudioStatusDescription() {
    if (!_enabled) return '音频已禁用';
    if (_muted) return '静音';
    return '音量: ${(_volume * 100).toInt()}%';
  }

  /// Load persisted settings (e.g., from SharedPreferences).
  void loadFromSettings({bool? enableAudio, double? audioVolume}) {
    if (enableAudio != null) {
      _enabled = enableAudio;
    }
    if (audioVolume != null) {
      _volume = audioVolume.clamp(0.0, 1.0);
    }
    _logger.i(
      'Audio settings loaded: enabled=$_enabled, volume=${(_volume * 100).toInt()}%',
    );
  }

  /// Restore defaults (enabled, full volume, no mute).
  Future<void> resetToDefault() async {
    _enabled = true;
    _volume = 1.0;
    _muted = false;
    await _applyVolumeToActiveRenderers();
    _logger.i('Audio settings reset to default');
  }

  Future<void> _applyVolumeToActiveRenderers() async {
    await _ensurePlatformAudioSession();

    if (_trackedAudioTracks.isEmpty) {
      _logger.d(
        'Audio settings updated - Volume: ${(_volume * 100).toInt()}%, Enabled: $_enabled, Muted: $_muted, Tracks: 0',
      );
      return;
    }

    final futures = <Future<void>>[];
    for (final track
        in List<MediaStreamTrack>.from(_trackedAudioTracks.values)) {
      futures.add(_applySettingsToTrack(track));
    }
    await Future.wait(futures, eagerError: false);

    _logger.d(
      'Applied audio settings - Volume: ${(_volume * 100).toInt()}%, Enabled: $_enabled, Muted: $_muted, Tracks: ${_trackedAudioTracks.length}',
    );
  }

  Future<void> _applySettingsToTrack(MediaStreamTrack track) async {
    if (track.kind != 'audio') return;

    try {
      // Always enable the track first
      track.enabled = _enabled && !_muted;
      _logger.d('Track ${_trackKey(track)} enabled set to: ${track.enabled}');

      // Try to set volume via Helper API
      try {
        await Helper.setVolume(effectiveVolume, track);
        _logger.d(
            'Volume set to ${effectiveVolume} for track ${_trackKey(track)}');
      } catch (volumeError) {
        // Volume setting may not be supported on all platforms (Windows desktop)
        // This is not fatal - the track will still play at system volume
        _logger
            .d('Helper.setVolume not supported on this platform: $volumeError');
      }
    } catch (e) {
      _logger
          .w('Failed to apply audio settings to track ${_trackKey(track)}: $e');
    }
  }

  Future<void> _ensurePlatformAudioSession() async {
    if (_audioSessionConfigured || kIsWeb) {
      _audioSessionConfigured = true;
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        try {
          await Helper.setSpeakerphoneOn(true);
        } catch (e) {
          _logger.w('Failed to enable Android speakerphone: $e');
        }
        break;
      case TargetPlatform.iOS:
        try {
          await Helper.ensureAudioSession();
          await Helper.setSpeakerphoneOn(true);
        } catch (e) {
          _logger.w('Failed to configure iOS audio session: $e');
        }
        break;
      default:
        // Desktop/web platforms do not need explicit routing tweaks.
        _logger.d(
            'Desktop platform detected, skipping audio session configuration');
        break;
    }

    _audioSessionConfigured = true;
  }

  String _trackKey(MediaStreamTrack track) =>
      track.id ?? track.hashCode.toString();
}
