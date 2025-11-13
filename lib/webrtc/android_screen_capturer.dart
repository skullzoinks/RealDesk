import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'screen_capture_permission.dart';

/// Handles Android screen + microphone capture via flutter_webrtc.
class AndroidScreenCapturer {
  AndroidScreenCapturer({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  MediaStream? _screenStream;
  MediaStream? _microphoneStream;
  final Set<String?> _stoppedTrackIds = <String?>{};

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isCapturing => _screenStream != null;

  MediaStream? get stream => _screenStream;

  /// Starts screen capture (and microphone capture if [withAudio] is true).
  Future<MediaStream?> start({bool withAudio = true}) async {
    if (!isSupported) {
      _logger.w('Android screen capture is not supported on this platform');
      return null;
    }
    if (_screenStream != null) {
      return _screenStream;
    }

    try {
      // Request screen capture permission first on Android
      final Completer<bool> permissionCompleter = Completer<bool>();

      ScreenCapturePermissionManager.setPermissionCallback((granted) {
        if (!permissionCompleter.isCompleted) {
          permissionCompleter.complete(granted);
        }
      });

      await ScreenCapturePermissionManager.requestPermission();
      final bool permissionGranted = await permissionCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );

      if (!permissionGranted) {
        throw Exception('Screen capture permission denied');
      }

      // On Android, use display media with proper constraints
      final Map<String, dynamic> constraints = {
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '15',
            'maxFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        },
      };

      // Try to get display media (screen sharing)
      _screenStream = await navigator.mediaDevices.getDisplayMedia(constraints);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to start screen capture: $e',
        error: e,
        stackTrace: stackTrace,
      );
      await stop();
      rethrow;
    }

    if (withAudio) {
      try {
        _microphoneStream =
            await navigator.mediaDevices.getUserMedia({'audio': true});
        final audioTracks =
            _microphoneStream?.getAudioTracks() ?? const <MediaStreamTrack>[];
        for (final track in audioTracks) {
          await _screenStream!.addTrack(track);
        }
      } catch (e, stackTrace) {
        _logger.w(
          'Microphone capture failed: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    return _screenStream;
  }

  Future<void> stop() async {
    Future<void> disposeStream(MediaStream? stream) async {
      if (stream == null) return;
      final tracks = List<MediaStreamTrack>.from(stream.getTracks());
      for (final track in tracks) {
        if (_stoppedTrackIds.add(track.id)) {
          try {
            track.stop();
          } catch (e) {
            _logger.w('Failed to stop track ${track.id}: $e');
          }
          try {
            await track.dispose();
          } catch (e) {
            _logger.w('Failed to dispose track ${track.id}: $e');
          }
        }
      }
      await stream.dispose();
    }

    await disposeStream(_screenStream);
    await disposeStream(_microphoneStream);
    _screenStream = null;
    _microphoneStream = null;
    _stoppedTrackIds.clear();
  }
}
