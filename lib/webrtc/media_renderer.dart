import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

/// Media renderer widget for displaying remote video stream
class RemoteMediaRenderer extends StatefulWidget {
  const RemoteMediaRenderer({
    required this.stream,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    this.mirror = false,
    this.onFirstFrame,
    this.onVideoSizeChanged,
    Key? key,
  }) : super(key: key);

  final MediaStream? stream;
  final RTCVideoViewObjectFit objectFit;
  final bool mirror;
  final VoidCallback? onFirstFrame;
  final void Function(int width, int height)? onVideoSizeChanged;

  @override
  State<RemoteMediaRenderer> createState() => _RemoteMediaRendererState();
}

class _RemoteMediaRendererState extends State<RemoteMediaRenderer> {
  final _renderer = RTCVideoRenderer();
  final _logger = Logger();
  bool _initialized = false;
  int _lastVideoWidth = 0;
  int _lastVideoHeight = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(RemoteMediaRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream) {
      _updateStream();
    }
  }

  Future<void> _initialize() async {
    try {
      await _renderer.initialize();
      _renderer.addListener(_handleRendererValueChanged);
      setState(() {
        _initialized = true;
      });
      _updateStream();
      _logger.i('Video renderer initialized');
    } catch (e) {
      _logger.e('Failed to initialize renderer: $e');
    }
  }

  void _updateStream() {
    if (!_initialized) return;

    _renderer.srcObject = widget.stream;
    if (widget.stream != null) {
      _logger.i('Stream attached to renderer');
      widget.onFirstFrame?.call();
    }
    _handleRendererValueChanged();
  }

  void _handleRendererValueChanged() {
    final width = _renderer.videoWidth;
    final height = _renderer.videoHeight;
    if (width <= 0 || height <= 0) {
      return;
    }
    if (width == _lastVideoWidth && height == _lastVideoHeight) {
      return;
    }
    _lastVideoWidth = width;
    _lastVideoHeight = height;
    widget.onVideoSizeChanged?.call(width, height);
  }

  @override
  void dispose() {
    _renderer.removeListener(_handleRendererValueChanged);
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.stream == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Waiting for stream...',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return RTCVideoView(
      _renderer,
      objectFit: widget.objectFit,
      mirror: widget.mirror,
    );
  }
}

/// Audio-only renderer
class AudioRenderer {
  AudioRenderer() : _logger = Logger();

  final _renderer = RTCVideoRenderer();
  final Logger _logger;
  bool _initialized = false;

  /// Get the underlying renderer (needed for rendering in widget tree)
  RTCVideoRenderer get renderer => _renderer;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _renderer.initialize();
      _initialized = true;
      _logger.i('Audio renderer initialized');
    } catch (e) {
      _logger.e('Failed to initialize audio renderer: $e');
    }
  }

  void setStream(MediaStream? stream) {
    if (!_initialized) {
      _logger.w('Cannot set stream - audio renderer not initialized');
      return;
    }
    
    _renderer.srcObject = stream;
    
    if (stream != null) {
      final audioTracks = stream.getAudioTracks();
      _logger.i('Audio stream (${stream.id}) attached to renderer with ${audioTracks.length} audio track(s)');
      for (var track in audioTracks) {
        _logger.i('  - Audio track: ${track.id}, enabled=${track.enabled}');
      }
    } else {
      _logger.i('Audio stream cleared from renderer');
    }
  }

  void dispose() {
    _renderer.dispose();
  }
}
