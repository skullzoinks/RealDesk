import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

import '../../input/gamepad_controller.dart';
import '../../input/keyboard_controller.dart';
import '../../input/mouse_controller.dart';
import '../../input/mouse_geometry.dart';
import '../../input/input_injector.dart';
import '../../input/schema/input_messages.dart';
import '../../input/schema/remote_input.pb.dart' as pb;
import '../../metrics/stats_collector.dart';
import '../../metrics/qos_congestion_controller.dart';
import '../../metrics/qos_data_manager.dart';
import '../../models/display_mode.dart';
import '../../signaling/signaling_client.dart';
import '../../signaling/models/signaling_messages.dart' as signaling;
import '../../webrtc/android_screen_capturer.dart';
import '../../webrtc/data_channel.dart';
import '../../webrtc/media_renderer.dart';
import '../../webrtc/peer_manager.dart';
import '../../settings/settings_model.dart';
import '../../settings/settings_store.dart';
import '../../utils/orientation_manager.dart';
import '../../utils/audio_manager.dart';
import '../widgets/control_bar.dart';
import '../widgets/metrics_overlay.dart';
import '../widgets/orientation_dialog.dart';
import '../widgets/switch_loading_screen.dart';
import '../widgets/switch_notification.dart';
import '../widgets/switch_confirm_dialog.dart';

/// Remote session page with video stream and input handling
class SessionPage extends StatefulWidget {
  const SessionPage({
    required this.signalingUrl,
    required this.roomId,
    this.token,
    Key? key,
  }) : super(key: key);

  final String signalingUrl;
  final String roomId;
  final String? token;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final _logger = Logger();
  final _videoKey = GlobalKey();
  final _focusNode = FocusNode(
    canRequestFocus: true,
    descendantsAreFocusable: false,
  );

  // Performance optimization: throttle pointer events
  DateTime _lastPointerEventTime = DateTime.now();
  static const _pointerEventThrottleMs = 8; // ~120Hz max

  late SignalingClient _signalingClient;
  late PeerManager _peerManager;
  final AndroidScreenCapturer _androidScreenCapturer = AndroidScreenCapturer();

  DataChannelManager? _dataChannelManager;
  MouseController? _mouseController;
  KeyboardController? _keyboardController;
  GamepadController? _gamepadController;
  StatsCollector? _statsCollector;
  QoSCongestionController? _qosController;
  QoSDataChannelManager? _qosDataManager;
  QoSIntegrationHelper? _qosIntegration;
  AudioRenderer? _audioRenderer;
  InputInjector? _inputInjector;

  MediaStream? _remoteStream;
  bool _isConnected = false;
  bool _showMetrics = false;
  MouseMode _mouseMode = MouseMode.absolute;
  String _statusMessage = '正在连接...';
  RealDeskSettings _settings = RealDeskSettings();
  bool _isFullScreen = false;
  DisplayMode _displayMode = DisplayMode.contain;

  StreamSubscription<RTCDataChannelMessage>? _dataChannelSubscription;
  ui.Image? _remoteCursorImage;
  bool _remoteCursorVisible = false;
  Offset _cursorHotspot = Offset.zero;
  // Pointer position for local rendering of remote cursor
  final ValueNotifier<Offset> _pointerPositionNotifier =
      ValueNotifier(Offset.zero);
  Offset get _pointerPosition => _pointerPositionNotifier.value;
  set _pointerPosition(Offset value) => _pointerPositionNotifier.value = value;
  bool _isPointerInsideVideo = false;
  int _cursorImageVersion = 0;
  Size _remoteVideoSize = Size.zero;

  bool get _shouldShowRemoteCursor =>
      _remoteCursorImage != null &&
      _remoteCursorVisible &&
      _isPointerInsideVideo;

  // 在FPS模式或有远程光标时隐藏本地光标
  bool get _shouldHideLocalCursor {
    if (_isPointerInsideVideo && _mouseMode == MouseMode.relative) {
      return true;
    }
    return _remoteCursorImage != null && _isPointerInsideVideo;
  }

  bool get _supportsNativeFullScreen =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Get filter quality based on settings
  FilterQuality get _videoFilterQuality {
    switch (_settings.videoRenderQuality) {
      case VideoRenderQuality.low:
        return FilterQuality.low;
      case VideoRenderQuality.medium:
        return FilterQuality.medium;
      case VideoRenderQuality.high:
        return FilterQuality.high;
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _logger.i('Initializing session');

    // Load settings
    _settings = await SettingsStore.load();

    // Configure audio manager
    AudioManager.instance.loadFromSettings(
      enableAudio: _settings.enableAudio,
      audioVolume: _settings.audioVolume,
    );

    // Initialize input injector for receiving remote control
    _inputInjector = InputInjector();
    await _inputInjector!.initialize();

    // Create signaling client with settings
    _signalingClient = SignalingClient(
      signalingUrl: widget.signalingUrl,
      reconnectDelay: Duration(seconds: _settings.reconnectDelaySeconds),
      maxReconnectAttempts: _settings.maxReconnectAttempts,
      allowInsecure: _settings.insecure,
    );
    _signalingClient.messageStream.listen(_onSignalingMessage);
    _signalingClient.stateStream.listen(_onSignalingStateChanged);

    // Create audio renderer for remote audio playback
    _audioRenderer = AudioRenderer();
    await _audioRenderer!.initialize();

    // Create peer manager (ICE will be set after accept)
    _peerManager = PeerManager(
      preferredVideoCodec: _settings.preferredVideoCodec,
    );
    _peerManager.remoteStream.listen(_onRemoteStream);
    _peerManager.iceCandidate.listen(_onIceCandidate);
    _peerManager.connectionState.listen(_onConnectionStateChanged);
    _peerManager.iceConnectionState.listen(_onIceConnectionStateChanged);
    _peerManager.dataChannelState.listen(_onDataChannelStateChanged);

    // Connect WS and send Ayame register
    await _signalingClient.connect();
    _signalingClient.sendRegister(
      roomId: widget.roomId,
      clientId: null,
      key: widget.token,
    );

    // apply defaults
    _showMetrics = _settings.defaultShowMetrics;
    _mouseMode = _settings.defaultMouseRelative
        ? MouseMode.relative
        : MouseMode.absolute;
  }

  void _onSignalingMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    _logger.d('Signaling message: $type');

    switch (type) {
      case 'accept':
        _handleAccept(message);
        break;
      case 'offer':
        _handleOffer(message);
        break;
      case 'answer':
        _handleAnswer(message);
        break;
      case 'candidate':
        _handleCandidate(message);
        break;
      case 'error':
        _handleError(message);
        break;
    }
  }

  Future<void> _handleAccept(Map<String, dynamic> message) async {
    final seen = <String>{};
    final effectiveIceServers = <Map<String, dynamic>>[];

    void addServer(dynamic server) {
      final normalized = _normalizeIceServer(server);
      if (normalized == null) return;
      if (_settings.noGoogleStun && _isGoogleStunServer(normalized)) return;
      final key = _iceServerKey(normalized);
      if (seen.add(key)) {
        effectiveIceServers.add(normalized);
      }
    }

    if (_settings.overrideIce) {
      try {
        final parsed = _settings.iceServersJson.trim().isEmpty
            ? const []
            : (jsonDecode(_settings.iceServersJson) as List);
        for (final server in parsed) {
          addServer(server);
        }
      } catch (e) {
        _logger.w('解析自定义 ICE 配置失败: $e');
      }
    } else {
      for (final server in RealDeskSettings.defaultIceServers) {
        addServer(server);
      }
      final ayameServers = (message['iceServers'] as List?) ?? const [];
      for (final server in ayameServers) {
        addServer(server);
      }
    }

    if (effectiveIceServers.isEmpty) {
      for (final server in RealDeskSettings.defaultIceServers) {
        addServer(server);
      }
    }

    await _peerManager.initializePeerConnectionWithIceServers(
      effectiveIceServers,
    );
    await _peerManager.createInputChannels();
    await _ensureAndroidScreenCapture();

    _dataChannelManager = DataChannelManager(
      rtChannel: _peerManager.rtChannel,
      reliableChannel: _peerManager.reliableChannel,
      useProtobuf: _settings.useProtobuf,
    );

    // Initialize input controllers
    _mouseController = MouseController(
      dataChannelManager: _dataChannelManager!,
      mode: _mouseMode,
    );
    _keyboardController = KeyboardController(
      dataChannelManager: _dataChannelManager!,
    );
    _gamepadController?.dispose();
    _gamepadController = GamepadController(
      dataChannelManager: _dataChannelManager!,
    )..start();

    _dataChannelSubscription?.cancel();
    _dataChannelSubscription = _peerManager.dataChannelMessage.listen(
      _onDataChannelMessage,
    );

    // If peer already exists, create offer
    final isExistUser = message['isExistUser'] == true;
    if (isExistUser) {
      final offer = await _peerManager.createOffer();
      _signalingClient.sendOffer(offer.sdp!);
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> message) async {
    final sdp = message['sdp'] as String;
    await _peerManager.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    );
    await _ensureAndroidScreenCapture();

    final answer = await _peerManager.createAnswer();
    _signalingClient.sendAnswer(answer.sdp!);
  }

  Future<void> _handleAnswer(Map<String, dynamic> message) async {
    final sdp = message['sdp'] as String;
    await _peerManager.setRemoteDescription(
      RTCSessionDescription(sdp, 'answer'),
    );
  }

  Future<void> _handleCandidate(Map<String, dynamic> message) async {
    // Ayame nested ice object
    final ice = message['ice'] as Map<String, dynamic>?;
    if (ice == null) return;
    final candidate = ice['candidate'] as String;
    final sdpMid = ice['sdpMid'] as String;
    final sdpMLineIndex = (ice['sdpMLineIndex'] as num).toInt();
    await _peerManager.addIceCandidate(
      RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
    );
  }

  Future<void> _ensureAndroidScreenCapture() async {
    if (!_androidScreenCapturer.isSupported) {
      return;
    }
    if (_peerManager.peerConnection == null) {
      return;
    }

    // Check if local media sending is enabled
    if (!_settings.sendLocalMedia) {
      _logger.i('Local media sending is disabled in settings');
      return;
    }

    try {
      final stream = await _androidScreenCapturer.start();
      if (stream == null) {
        return;
      }
      if (identical(stream, _peerManager.localStream)) {
        return;
      }
      await _peerManager.setLocalMediaStream(stream);
      _logger.i('Android screen capture attached');
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to start Android screen capture: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _showScreenCaptureError(e);
    }
  }

  Future<void> _teardownAndroidScreenCapture() async {
    if (!_androidScreenCapturer.isSupported) {
      return;
    }
    if (_peerManager.peerConnection != null &&
        _peerManager.localStream != null) {
      try {
        await _peerManager.setLocalMediaStream(null);
      } catch (e, stackTrace) {
        _logger.w(
          'Failed to detach local stream: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    try {
      await _androidScreenCapturer.stop();
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to stop Android screen capture: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _showScreenCaptureError(Object error) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('无法开启屏幕捕获: ${_screenCaptureErrorMessage(error)}'),
      ),
    );
  }

  String _screenCaptureErrorMessage(Object error) {
    if (error is PlatformException) {
      final message = error.message;
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return error.code;
    }
    return error.toString();
  }

  void _handleError(Map<String, dynamic> message) {
    final errorMessage = message['message'] as String?;
    _logger.e('Signaling error: $errorMessage');
    setState(() {
      _statusMessage = '错误: $errorMessage';
    });
  }

  void _onSignalingStateChanged(signaling.ConnectionState state) {
    _logger.i('Signaling state: $state');
    setState(() {
      _statusMessage = _getStateMessage(state);
    });
  }

  void _onRemoteStream(MediaStream stream) {
    _logger.i(
        'Received remote stream with ${stream.getVideoTracks().length} video tracks and ${stream.getAudioTracks().length} audio tracks');

    final previousStream = _remoteStream;
    final isNewStream =
        previousStream == null || previousStream.id != stream.id;

    setState(() {
      _remoteStream = stream;
    });

    if (previousStream != null && previousStream.id != stream.id) {
      AudioManager.instance.unregisterMediaStream(previousStream);
    }

    // Set up audio playback (always call to handle new tracks)
    unawaited(_setupAudioPlayback(stream));

    // Start stats collection only for new streams
    if (isNewStream && _peerManager.peerConnection != null) {
      _statsCollector?.dispose();
      _statsCollector = StatsCollector(
        peerConnection: _peerManager.peerConnection!,
      );
      _statsCollector!.start();
    }

    // Request focus for keyboard input (without showing soft keyboard)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        // Hide soft keyboard on Android
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
  }

  Future<void> _setupAudioPlayback(MediaStream stream) async {
    final audioTracks = stream.getAudioTracks();
    _logger.i(
        'Setting up audio playback for ${audioTracks.length} audio track(s)');

    if (audioTracks.isEmpty) {
      _logger.w('No audio tracks found in remote stream');
      return;
    }

    if (_audioRenderer == null) {
      _logger.e('Audio renderer not initialized');
      return;
    }

    // Log audio track details before configuration
    for (var track in audioTracks) {
      _logger.i(
          'Audio track BEFORE config: id=${track.id}, kind=${track.kind}, enabled=${track.enabled}, muted=${track.muted}');
    }

    // First, set stream to renderer so platform can see the stream
    _audioRenderer!.setStream(stream);

    // Then configure audio tracks with current settings
    try {
      await AudioManager.instance.configureMediaStream(stream);
      _logger.i('Audio manager configuration completed');
    } catch (e) {
      _logger.e('Failed to configure audio manager: $e');
    }

    // Log audio track details after configuration
    for (var track in audioTracks) {
      _logger.i(
          'Audio track AFTER config: id=${track.id}, kind=${track.kind}, enabled=${track.enabled}, muted=${track.muted}');
    }

    _logger.i(
        'Audio playback configured: ${AudioManager.instance.getAudioStatusDescription()}');
  }

  void _onIceCandidate(RTCIceCandidate candidate) {
    _signalingClient.sendCandidate(
      candidate.candidate!,
      candidate.sdpMid!,
      candidate.sdpMLineIndex!,
    );
  }

  void _onConnectionStateChanged(RTCPeerConnectionState state) {
    _logger.i('Connection state: $state');
    setState(() {
      _isConnected =
          state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      _statusMessage = _getConnectionStateMessage(state);
    });
  }

  void _onIceConnectionStateChanged(RTCIceConnectionState state) {
    _logger.i('ICE connection state: $state');

    // Show user-friendly status messages for ICE state changes
    String? message;
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        message = '正在建立连接...';
        break;
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        message = '连接成功';
        // Stream refresh is handled by RemoteMediaRenderer internally
        // Removed unnecessary setState to reduce CPU usage
        _logger.i('ICE reconnected - stream will refresh automatically');
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        message = '连接中断，正在尝试重连...';
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        message = '连接失败，请检查网络';
        break;
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        message = '连接已关闭';
        break;
      default:
        break;
    }

    if (message != null && mounted) {
      SwitchNotificationType type = SwitchNotificationType.info;
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        type = SwitchNotificationType.success;
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        type = SwitchNotificationType.error;
      }
      _showNotification(message, type: type);
    }
  }

  void _onDataChannelStateChanged(RTCDataChannelState state) {
    _logger.i('Data channel state: $state');

    if (state == RTCDataChannelState.RTCDataChannelOpen) {
      unawaited(_initializeQoSSystem());
    } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
      _shutdownQoSSystem();
    }
  }

  /// Initialize QoS congestion control system
  Future<void> _initializeQoSSystem() async {
    if (!_settings.enableQoS) {
      _logger.d('QoS disabled in settings; skipping initialization');
      return;
    }

    if (_qosController != null) {
      _logger.d('QoS system already initialized');
      return;
    }

    final connection = _peerManager.peerConnection;
    final statsCollector = _statsCollector;

    if (connection == null || statsCollector == null) {
      _logger.w(
          'Cannot initialize QoS: missing peer connection or stats collector');
      return;
    }

    try {
      final config = QoSConfig(
        pollIntervalMs: statsCollector.collectInterval.inMilliseconds,
        highLossPercentage: _settings.qosHighLossPercentage,
        highRttMs: _settings.qosHighRttMs,
        highJitterMs: _settings.qosHighJitterMs,
        increaseStep: _settings.qosBitrateIncreaseStep,
        decreaseStep: _settings.qosBitrateDecreaseStep,
        healthySamplesRequired: _settings.qosHealthySamplesRequired,
        maxBitrateBps: _settings.qosMaxBitrate * 1000,
        minBitrateBps: _settings.qosMinBitrate * 1000,
      );

      _qosController = QoSCongestionController(
        statsCollector: statsCollector,
        config: config,
        onBitrateAdjustment: _handleBitrateAdjustment,
        onMetricsUpdate: _handleQoSMetricsUpdate,
      );

      _qosDataManager = QoSDataChannelManager(
        peerConnection: connection,
        onMessage: _handleQoSMessage,
      );

      _qosIntegration = QoSIntegrationHelper(
        congestionController: _qosController!,
        dataChannelManager: _qosDataManager!,
      );

      await _qosDataManager!.initialize();
      _qosIntegration!.start();
      _qosController!.start();
      _logger.i('QoS system initialized successfully');
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to initialize QoS system: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _shutdownQoSSystem();
    }
  }

  /// Shutdown QoS system
  void _shutdownQoSSystem() {
    _qosController?.stop();
    _qosIntegration?.stop();
    _qosDataManager?.close();

    _qosController = null;
    _qosIntegration = null;
    _qosDataManager = null;

    _logger.i('QoS system shutdown');
  }

  /// Handle bitrate adjustment from QoS controller
  void _handleBitrateAdjustment(int minBitrate, int maxBitrate) {
    _logger.i(
        'Applying bitrate adjustment request: min=$minBitrate, max=$maxBitrate');

    // Notify remote host via QoS data channel so it can adjust encoder bitrate
    _qosDataManager?.sendBitrateCommand(
      maxBitrate,
      minBitrate: minBitrate,
      maxBitrate: maxBitrate,
    );
  }

  /// Handle QoS metrics updates
  void _handleQoSMetricsUpdate(EnhancedQoSMetrics metrics) {
    _qosIntegration?.forwardMetrics(metrics);
  }

  /// Handle incoming QoS messages from remote
  void _handleQoSMessage(QoSMessage message) {
    _qosIntegration?.handleQoSMessage(message);
  }

  /// Change video codec preference and renegotiate connection
  Future<void> changeVideoCodec(String codec) async {
    if (!_isConnected) {
      _logger.w('Cannot change codec: not connected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未连接,无法切换编码格式')),
        );
      }
      return;
    }

    try {
      _logger.i('Changing video codec to: $codec');
      await _peerManager.setPreferredCodec(codec, renegotiate: false);

      // Create new offer with updated codec preference
      final offer = await _peerManager.createOffer();

      // Send offer through signaling
      _signalingClient.sendOffer(offer.sdp!);

      if (mounted) {
        _showNotification('正在切换到 $codec 编码...');
      }

      _logger.i('Codec change offer sent, waiting for answer');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to change codec: $e',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showNotification('切换编码失败: $e', type: SwitchNotificationType.error);
      }
    }
  }

  /// Manually restart ICE connection
  Future<void> restartIceConnection() async {
    if (_peerManager.peerConnection == null) {
      _logger.w('Cannot restart ICE: peer connection not available');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接不可用')),
        );
      }
      return;
    }

    try {
      _logger.i('Manually restarting ICE connection');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在重新建立连接...')),
        );
      }

      final offer = await _peerManager.restartIce();
      if (offer != null && offer.sdp != null) {
        _signalingClient.sendOffer(offer.sdp!);
        _logger.i('ICE restart offer sent');
      } else {
        throw Exception('Failed to create ICE restart offer');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to restart ICE: $e',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重连失败: $e')),
        );
      }
    }
  }

  void _onDataChannelMessage(RTCDataChannelMessage message) {
    // Handle Protobuf binary messages
    if (message.isBinary) {
      _handleProtobufMessage(message.binary);
      return;
    }

    // Handle JSON text messages
    final text = message.text;
    if (text.isEmpty) {
      return;
    }

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    } catch (e) {
      _logger.w('解析 DataChannel 文本消息失败: $e');
      return;
    }

    if (payload == null) {
      return;
    }

    final type = payload['type'] as String?;
    if (type == null) {
      return;
    }

    switch (type) {
      case 'cursorImage':
        _handleCursorImageMessage(payload);
        break;
      case 'mouseAbs':
        _handleMouseAbsoluteMessage(payload);
        break;
      case 'mouseRel':
        _handleMouseRelativeMessage(payload);
        break;
      case 'mouseWheel':
        _handleMouseWheelMessage(payload);
        break;
      case 'keyboard':
        _handleKeyboardMessage(payload);
        break;
      case 'touch':
        _handleTouchMessage(payload);
        break;
      case 'gamepadFeedback':
        _handleGamepadFeedback(payload);
        break;
      default:
        _logger.d('Unknown data channel message type: $type');
        break;
    }
  }

  /// Handle incoming Protobuf binary messages
  void _handleProtobufMessage(Uint8List data) {
    try {
      final envelope = pb.Envelope.fromBuffer(data);
      final payload = envelope.whichPayload();

      switch (payload) {
        case pb.Envelope_Payload.cursorImage:
          _handleCursorImageProtobuf(envelope.cursorImage);
          break;
        case pb.Envelope_Payload.mouseAbs:
          _handleMouseAbsoluteProtobuf(envelope.mouseAbs);
          break;
        case pb.Envelope_Payload.mouseRel:
          _handleMouseRelativeProtobuf(envelope.mouseRel);
          break;
        case pb.Envelope_Payload.mouseWheel:
          _handleMouseWheelProtobuf(envelope.mouseWheel);
          break;
        case pb.Envelope_Payload.keyboard:
          _handleKeyboardProtobuf(envelope.keyboard);
          break;
        case pb.Envelope_Payload.gamepadFeedback:
          _handleGamepadFeedbackProtobuf(envelope.gamepadFeedback);
          break;
        case pb.Envelope_Payload.imeState:
          // IME state not yet implemented
          _logger.d('收到 IME 状态消息 (未实现)');
          break;
        case pb.Envelope_Payload.gamepadXInput:
        case pb.Envelope_Payload.gamepadConnection:
          // These are outgoing messages from controller to controlled
          _logger.d('收到游戏手柄消息 (不应该从远程收到)');
          break;
        case pb.Envelope_Payload.notSet:
          _logger.w('收到空的 Protobuf 消息');
          break;
      }
    } catch (e) {
      _logger.w('解析 Protobuf 消息失败: $e');
    }
  }

  /// Handle incoming mouse absolute position event
  void _handleMouseAbsoluteMessage(Map<String, dynamic> payload) {
    final x = (payload['x'] as num?)?.toDouble();
    final y = (payload['y'] as num?)?.toDouble();
    final displayW = (payload['displayW'] as num?)?.toInt();
    final displayH = (payload['displayH'] as num?)?.toInt();
    final buttons = (payload['buttons'] as num?)?.toInt() ?? 0;

    if (x == null || y == null || displayW == null || displayH == null) {
      _logger.w('Invalid mouseAbs message: missing required fields');
      return;
    }

    _inputInjector?.injectMouseAbsolute(
      x: x,
      y: y,
      displayW: displayW,
      displayH: displayH,
      buttons: buttons,
    );

    // In relative mode, update cursor position from remote absolute position
    if (_mouseMode == MouseMode.relative) {
      _updateCursorPositionFromRemote(x, y, displayW, displayH);
    }
  }

  /// Handle incoming mouse relative movement event
  void _handleMouseRelativeMessage(Map<String, dynamic> payload) {
    final dx = (payload['dx'] as num?)?.toDouble();
    final dy = (payload['dy'] as num?)?.toDouble();
    final buttons = (payload['buttons'] as num?)?.toInt() ?? 0;

    if (dx == null || dy == null) {
      _logger.w('Invalid mouseRel message: missing required fields');
      return;
    }

    _inputInjector?.injectMouseRelative(
      dx: dx,
      dy: dy,
      buttons: buttons,
    );
  }

  /// Handle incoming mouse wheel/scroll event
  void _handleMouseWheelMessage(Map<String, dynamic> payload) {
    final dx = (payload['dx'] as num?)?.toDouble();
    final dy = (payload['dy'] as num?)?.toDouble();

    if (dx == null || dy == null) {
      _logger.w('Invalid mouseWheel message: missing required fields');
      return;
    }

    _inputInjector?.injectMouseWheel(dx: dx, dy: dy);
  }

  /// Handle incoming keyboard event
  void _handleKeyboardMessage(Map<String, dynamic> payload) {
    final key = payload['key'] as String?;
    final code = (payload['code'] as num?)?.toInt() ?? 0;
    final down = payload['down'] as bool? ?? false;
    final mods = (payload['mods'] as num?)?.toInt() ?? 0;

    if (key == null) {
      _logger.w('Invalid keyboard message: missing key field');
      return;
    }

    _inputInjector?.injectKeyboard(
      key: key,
      code: code,
      down: down,
      mods: mods,
    );
  }

  /// Handle incoming touch event
  void _handleTouchMessage(Map<String, dynamic> payload) {
    final touches = payload['touches'] as List<dynamic>?;

    if (touches == null) {
      _logger.w('Invalid touch message: missing touches field');
      return;
    }

    final touchList = touches.whereType<Map<String, dynamic>>().toList();

    _inputInjector?.injectTouch(touches: touchList);
  }

  void _handleGamepadFeedback(Map<String, dynamic> payload) {
    final index = (payload['index'] as num?)?.toInt();
    if (index == null) {
      _logger.w('Invalid gamepadFeedback message: missing index');
      return;
    }
    final large = (payload['largeMotor'] as num?)?.toDouble() ?? 0.0;
    final small = (payload['smallMotor'] as num?)?.toDouble() ?? 0.0;
    final ledCode = (payload['ledCode'] as num?)?.toInt() ?? -1;
    _gamepadController?.handleFeedback(
      index: index,
      largeMotor: large,
      smallMotor: small,
      ledCode: ledCode,
    );
  }

  // ========== Protobuf Message Handlers ==========

  /// Handle incoming cursor image (Protobuf format)
  void _handleCursorImageProtobuf(pb.CursorImage cursor) {
    final width = cursor.w;
    final height = cursor.h;
    final rgba = cursor.rgba;

    _logger.i(
        '收到光标图像消息 [Protobuf]: width=$width, height=$height, dataLength=${rgba.length}');

    if (width <= 0 || height <= 0 || rgba.isEmpty) {
      _logger.w('收到的 cursorImage 消息字段缺失或非法 [Protobuf]');
      return;
    }

    final expectedLength = width * height * 4;
    if (rgba.length < expectedLength) {
      _logger.w(
          'cursorImage 数据长度不足 [Protobuf]: 实际 ${rgba.length} 字节, 期望 $expectedLength');
      return;
    }

    final hotspotX = cursor.hotspotX.toDouble();
    final hotspotY = cursor.hotspotY.toDouble();
    final visible = cursor.hasVisible() ? cursor.visible : true;

    final version = ++_cursorImageVersion;

    try {
      // Protobuf uses RGBA, need to convert to BGRA for Flutter
      final bgra = Uint8List(rgba.length);
      for (int i = 0; i < rgba.length; i += 4) {
        bgra[i] = rgba[i + 2]; // B
        bgra[i + 1] = rgba[i + 1]; // G
        bgra[i + 2] = rgba[i]; // R
        bgra[i + 3] = rgba[i + 3]; // A
      }

      ui.decodeImageFromPixels(bgra, width, height, ui.PixelFormat.bgra8888, (
        ui.Image image,
      ) {
        if (!mounted) {
          image.dispose();
          return;
        }

        if (version != _cursorImageVersion) {
          image.dispose();
          return;
        }

        final previous = _remoteCursorImage;

        setState(() {
          _remoteCursorImage = image;
          _cursorHotspot = Offset(hotspotX, hotspotY);
          _remoteCursorVisible = visible;

          // Auto-switch logic for FPS games
          if (!visible && _mouseMode == MouseMode.absolute) {
             _mouseMode = MouseMode.relative;
             _mouseController?.toggleMode();
             _showNotification('Entering FPS Mode (Relative Mouse)', type: SwitchNotificationType.info);
          } else if (visible && _mouseMode == MouseMode.relative) {
             _mouseMode = MouseMode.absolute;
             _mouseController?.toggleMode();
             _showNotification('Exiting FPS Mode (Absolute Mouse)', type: SwitchNotificationType.info);
          }

          _logger.i(
              '光标图像已设置 [Protobuf]: ${image.width}x${image.height}, hotspot=($hotspotX,$hotspotY), visible=$visible');
        });

        previous?.dispose();
      }, rowBytes: width * 4);
    } catch (e) {
      _logger.w('cursorImage 像素解码失败 [Protobuf]: $e');
    }
  }

  /// Handle incoming mouse absolute position (Protobuf format)
  void _handleMouseAbsoluteProtobuf(pb.MouseAbs mouseAbs) {
    final x = mouseAbs.x;
    final y = mouseAbs.y;
    final displayW = mouseAbs.displayW;
    final displayH = mouseAbs.displayH;
    final buttons = mouseAbs.btns.bits;

    _inputInjector?.injectMouseAbsolute(
      x: x,
      y: y,
      displayW: displayW,
      displayH: displayH,
      buttons: buttons,
    );

    // In relative mode, update cursor position from remote absolute position
    if (_mouseMode == MouseMode.relative) {
      _updateCursorPositionFromRemote(x, y, displayW, displayH);
    }
  }

  /// Handle incoming mouse relative movement (Protobuf format)
  void _handleMouseRelativeProtobuf(pb.MouseRel mouseRel) {
    final dx = mouseRel.dx;
    final dy = mouseRel.dy;
    final buttons = mouseRel.btns.bits;

    _inputInjector?.injectMouseRelative(
      dx: dx,
      dy: dy,
      buttons: buttons,
    );
  }

  /// Handle incoming mouse wheel/scroll (Protobuf format)
  void _handleMouseWheelProtobuf(pb.MouseWheel mouseWheel) {
    final dx = mouseWheel.dx;
    final dy = mouseWheel.dy;

    _inputInjector?.injectMouseWheel(dx: dx, dy: dy);
  }

  /// Handle incoming keyboard event (Protobuf format)
  void _handleKeyboardProtobuf(pb.Keyboard keyboard) {
    final key = keyboard.key;
    final code = keyboard.code;
    final down = keyboard.down;
    final mods = keyboard.mods;

    _inputInjector?.injectKeyboard(
      key: key,
      code: code,
      down: down,
      mods: mods,
    );
  }

  /// Handle incoming gamepad feedback (Protobuf format)
  void _handleGamepadFeedbackProtobuf(pb.GamepadFeedback feedback) {
    final index = feedback.index;
    final large = feedback.largeMotor;
    final small = feedback.smallMotor;
    final ledCode = feedback.hasLedCode() ? feedback.ledCode : -1;

    _gamepadController?.handleFeedback(
      index: index,
      largeMotor: large,
      smallMotor: small,
      ledCode: ledCode,
    );
  }

  /// Update cursor position from remote absolute coordinates
  /// Used in relative mode to display cursor at the position sent by remote
  void _updateCursorPositionFromRemote(
    double remoteX,
    double remoteY,
    int remoteDisplayW,
    int remoteDisplayH,
  ) {
    if (!mounted) {
      return;
    }

    final viewSize = _getVideoSize();
    final geometry = _buildMouseGeometry(viewSize);
    if (viewSize.isEmpty || !geometry.hasVideoContent) {
      return;
    }

    final newPosition = geometry.mapRemoteToLocal(
      remoteX: remoteX,
      remoteY: remoteY,
      displayW: remoteDisplayW > 0 ? remoteDisplayW.toDouble() : null,
      displayH: remoteDisplayH > 0 ? remoteDisplayH.toDouble() : null,
    );

    // Only update if position changed significantly (reduce CPU usage)
    final dx = newPosition.dx - _pointerPosition.dx;
    final dy = newPosition.dy - _pointerPosition.dy;
    if ((dx * dx + dy * dy) < 1.0) {
      return;
    }

    _pointerPosition = newPosition;
    if (!_isPointerInsideVideo) {
      setState(() {
        _isPointerInsideVideo = true; // Ensure cursor is visible
      });
    }
  }

  void _handleCursorImageMessage(Map<String, dynamic> payload) {
    final width = (payload['w'] as num?)?.toInt();
    final height = (payload['h'] as num?)?.toInt();
    final data = payload['data'] as String?;

    _logger.i(
        '收到光标图像消息: width=$width, height=$height, dataLength=${data?.length ?? 0}');

    if (width == null ||
        height == null ||
        width <= 0 ||
        height <= 0 ||
        data == null) {
      _logger.w('收到的 cursorImage 消息字段缺失或非法');
      return;
    }

    final format = payload['fmt']?.toString();
    if (format != null && format.toUpperCase() != 'BGRA') {
      _logger.w('收到不支持的 cursorImage 格式: $format');
      return;
    }

    Uint8List raw;
    try {
      raw = base64Decode(data);
    } catch (e) {
      _logger.w('cursorImage 数据 base64 解码失败: $e');
      return;
    }

    final expectedLength = width * height * 4;
    if (raw.length < expectedLength) {
      _logger.w('cursorImage 数据长度不足: 实际 ${raw.length} 字节, 期望 $expectedLength');
      return;
    }

    final hotspotX = (payload['hotspotX'] as num?)?.toDouble() ?? 0;
    final hotspotY = (payload['hotspotY'] as num?)?.toDouble() ?? 0;
    final visible = payload['visible'] != false;

    final version = ++_cursorImageVersion;

    try {
      ui.decodeImageFromPixels(raw, width, height, ui.PixelFormat.bgra8888, (
        ui.Image image,
      ) {
        if (!mounted) {
          image.dispose();
          return;
        }

        if (version != _cursorImageVersion) {
          image.dispose();
          return;
        }

        final previous = _remoteCursorImage;

        setState(() {
          _remoteCursorImage = image;
          _cursorHotspot = Offset(hotspotX, hotspotY);
          _remoteCursorVisible = visible;
          
          // Auto-switch logic for FPS games
          if (!visible && _mouseMode == MouseMode.absolute) {
             _mouseMode = MouseMode.relative;
             _mouseController?.toggleMode(); // Ensure controller state matches
             _showNotification('Entering FPS Mode (Relative Mouse)', type: SwitchNotificationType.info);
          } else if (visible && _mouseMode == MouseMode.relative) {
             // Optional: Switch back to absolute if cursor reappears?
             // The prompt implies "until the remote server transmits mouse cursor information".
             // If we receive a visible cursor, it means we are back to normal.
             _mouseMode = MouseMode.absolute;
             _mouseController?.toggleMode();
             _showNotification('Exiting FPS Mode (Absolute Mouse)', type: SwitchNotificationType.info);
          }

          _logger.i(
              '光标图像已设置: ${image.width}x${image.height}, hotspot=($hotspotX,$hotspotY), visible=$visible');
        });

        previous?.dispose();
      }, rowBytes: width * 4);
    } catch (e) {
      _logger.w('cursorImage 像素解码失败: $e');
    }
  }

  void _handleVideoSizeChanged(int width, int height) {
    if (width <= 0 || height <= 0) {
      return;
    }
    final newSize = Size(width.toDouble(), height.toDouble());
    if (_remoteVideoSize == newSize) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _remoteVideoSize = newSize;
    });

    // 根据视频尺寸自动调整屏幕方向
    _autoAdjustOrientation(width, height);

    _logger.i(
      'Remote video size updated: ${newSize.width.toInt()}x${newSize.height.toInt()}',
    );
  }

  /// 根据视频尺寸自动调整屏幕方向
  Future<void> _autoAdjustOrientation(int width, int height) async {
    try {
      await OrientationManager.instance
          .adjustOrientationForVideo(width, height);
    } catch (e) {
      _logger.w('自动调整屏幕方向失败: $e');
    }
  }

  /// 切换屏幕方向
  Future<void> _toggleOrientation() async {
    try {
      await OrientationManager.instance.toggleOrientation();
      _showOrientationMessage();
    } catch (e) {
      _logger.w('切换屏幕方向失败: $e');
    }
  }

  /// 显示屏幕方向变化消息
  void _showOrientationMessage([String? message]) {
    final orientation = MediaQuery.of(context).orientation;
    final defaultMessage =
        '当前屏幕方向: ${OrientationManager.instance.getOrientationDescription(orientation)}';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? defaultMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 显示屏幕方向菜单
  Future<void> _showOrientationMenu() async {
    await showQuickOrientationSheet(context);
  }

  /// 切换音频开关
  Future<void> _toggleAudio() async {
    await AudioManager.instance.toggleMute();

    // 重新配置当前的音频流
    if (_remoteStream != null) {
      await AudioManager.instance.configureMediaStream(_remoteStream!);
    }

    setState(() {
      // 触发UI更新
    });

    // 显示音频状态
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AudioManager.instance.getAudioStatusDescription()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _updatePointerInside(bool inside) {
    if (_isPointerInsideVideo == inside) {
      return;
    }
    // Only trigger setState if cursor visibility will actually change
    if (_remoteCursorImage != null || inside != _isPointerInsideVideo) {
      setState(() {
        _isPointerInsideVideo = inside;
      });
    } else {
      _isPointerInsideVideo = inside;
    }
    // Reduced logging for performance
  }

  void _recordPointerPosition(
    PointerEvent event,
    MouseDisplayGeometry geometry,
  ) {
    if (!geometry.hasVideoContent) {
      return;
    }

    // In relative mode with remote cursor, position is defined by server updates only.
    // In absolute mode, position is defined by local mouse events.
    if (_shouldShowRemoteCursor && _mouseMode == MouseMode.relative) {
      return;
    }

    final adjusted = geometry.clampLocal(event.localPosition);
    final minDeltaSquared = _mouseMode == MouseMode.relative ? 0.16 : 1.0;

    if (_pointerPosition != adjusted) {
      // Only update if position changed significantly
      final dx = adjusted.dx - _pointerPosition.dx;
      final dy = adjusted.dy - _pointerPosition.dy;
      if ((dx * dx + dy * dy) < minDeltaSquared) {
        return;
      }
      _pointerPosition = adjusted;
    }
  }

  String _getStateMessage(signaling.ConnectionState state) {
    switch (state) {
      case signaling.ConnectionState.connecting:
        return '正在连接...';
      case signaling.ConnectionState.connected:
        return '已连接';
      case signaling.ConnectionState.reconnecting:
        return '正在重连...';
      case signaling.ConnectionState.disconnected:
        return '已断开';
      case signaling.ConnectionState.failed:
        return '连接失败';
    }
  }

  String _getConnectionStateMessage(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        return '准备中...';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return '正在建立连接...';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return '已连接';
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return '连接中断';
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return '连接失败';
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return '连接已关闭';
    }
  }

  void _toggleMetrics() {
    setState(() {
      _showMetrics = !_showMetrics;
    });
  }

  void _cycleDisplayMode() {
    setState(() {
      switch (_displayMode) {
        case DisplayMode.contain:
          _displayMode = DisplayMode.cover;
          break;
        case DisplayMode.cover:
          _displayMode = DisplayMode.fit;
          break;
        case DisplayMode.fit:
          _displayMode = DisplayMode.contain;
          break;
      }
    });

    // Show current mode
    String modeName;
    String modeDesc;
    switch (_displayMode) {
      case DisplayMode.contain:
        modeName = '默认比例';
        modeDesc = '保持原始比例，留黑边';
        break;
      case DisplayMode.cover:
        modeName = '全屏拉伸';
        modeDesc = '完整显示画面，不按比例缩放';
        break;
      case DisplayMode.fit:
        modeName = '适当拉伸';
        modeDesc = '移动端拉伸为20:9（其他平台保持拉伸）';
        break;
    }

    if (mounted) {
      _showNotification('$modeName: $modeDesc');
    }
  }

  void _toggleMouseMode() {
    setState(() {
      _mouseMode = _mouseMode == MouseMode.absolute
          ? MouseMode.relative
          : MouseMode.absolute;
      _mouseController?.toggleMode();
    });
  }

  Future<void> _setFullScreen(bool enable) async {
    if (_isFullScreen == enable) {
      return;
    }

    if (mounted) {
      setState(() {
        _isFullScreen = enable;
      });
    } else {
      _isFullScreen = enable;
    }

    if (_supportsNativeFullScreen) {
      try {
        await windowManager.setFullScreen(enable);
      } catch (e, stackTrace) {
        _logger.w('切换原生全屏失败: $e\n$stackTrace');
        if (enable) {
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky,
          );
        } else {
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
        return;
      }
      if (!enable) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      return;
    }

    if (enable) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleFullScreen() {
    _setFullScreen(!_isFullScreen);
  }

  void _disconnect() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => SwitchConfirmDialog(
        title: 'Exit Session',
        content: 'Are you sure you want to disconnect from the remote desktop?',
        confirmText: 'Exit',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () {
          _shutdownQoSSystem();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Size _getVideoSize() {
    final renderBox =
        _videoKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size ?? Size.zero;
  }

  MouseDisplayGeometry _buildMouseGeometry(Size viewSize) {
    if (viewSize.isEmpty) {
      return const MouseDisplayGeometry.empty();
    }
    return MouseDisplayGeometry.compute(
      viewSize: viewSize,
      remoteVideoSize: _remoteVideoSize,
      displayMode: _displayMode,
      forceMobileWide: _shouldForceMobileWideAspectRatio(),
    );
  }

  bool _shouldForceMobileWideAspectRatio() {
    if (kIsWeb) {
      return false;
    }
    final platform = defaultTargetPlatform;
    return _displayMode == DisplayMode.fit &&
        (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  }

  Map<String, dynamic>? _normalizeIceServer(dynamic server) {
    if (server is! Map) return null;
    final urls = _extractUrlsFrom(server['urls']);
    if (urls.isEmpty) return null;

    final normalized = <String, dynamic>{
      'urls': urls.length == 1 ? urls.first : urls,
    };

    if (server.containsKey('username') && server['username'] != null) {
      normalized['username'] = server['username'].toString();
    }
    if (server.containsKey('credential') && server['credential'] != null) {
      normalized['credential'] = server['credential'].toString();
    }
    if (server.containsKey('credentialType') &&
        server['credentialType'] != null) {
      normalized['credentialType'] = server['credentialType'].toString();
    }

    return normalized;
  }

  List<String> _extractUrlsFrom(dynamic urls) {
    if (urls is String) {
      return [urls];
    }
    if (urls is Iterable) {
      return urls
          .map((e) => e.toString())
          .where((value) => value.isNotEmpty)
          .toList();
    }
    return [];
  }

  bool _isGoogleStunServer(Map<String, dynamic> server) {
    final urls = _extractUrlsFrom(server['urls']);
    return urls.any((url) => url.contains('stun.l.google.com'));
  }

  String _iceServerKey(Map<String, dynamic> server) {
    final urls = _extractUrlsFrom(server['urls'])..sort();
    final username = server['username']?.toString() ?? '';
    final credential = server['credential']?.toString() ?? '';
    final credentialType = server['credentialType']?.toString() ?? '';
    return jsonEncode({
      'urls': urls,
      'username': username,
      'credential': credential,
      'credentialType': credentialType,
    });
  }

  IconData _getDisplayModeIcon() {
    switch (_displayMode) {
      case DisplayMode.contain:
        return Icons.fit_screen;
      case DisplayMode.cover:
        return Icons.fullscreen;
      case DisplayMode.fit:
        return Icons.aspect_ratio;
    }
  }

  String _getDisplayModeTooltip() {
    switch (_displayMode) {
      case DisplayMode.contain:
        return '默认比例 (点击切换到全屏拉伸)';
      case DisplayMode.cover:
        return '全屏拉伸 (点击切换到适当拉伸)';
      case DisplayMode.fit:
        return '适当拉伸 (点击切换到默认比例)';
    }
  }

  @override
  void dispose() {
    _shutdownQoSSystem();
    _dataChannelSubscription?.cancel();
    _remoteCursorImage?.dispose();
    _statsCollector?.dispose();
    _gamepadController?.dispose();
    AudioManager.instance.unregisterMediaStream(_remoteStream);
    _audioRenderer?.dispose();
    _inputInjector?.dispose();
    _focusNode.dispose();
    unawaited(_teardownAndroidScreenCapture());
    _peerManager.dispose();
    _signalingClient.dispose();
    if (_isFullScreen) {
      if (_supportsNativeFullScreen) {
        unawaited(windowManager.setFullScreen(false));
      }
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _pointerPositionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video layer - isolated with RepaintBoundary
          Positioned.fill(
            child: RepaintBoundary(
              child: _buildRemoteSurface(),
            ),
          ),
          
          // Control bar layer - positioned at bottom
          if (!_isFullScreen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: ControlBar(
                  isConnected: _isConnected,
                  showMetrics: _showMetrics,
                  mouseMode: _mouseMode,
                  onToggleMetrics: _toggleMetrics,
                  onToggleMouseMode: _toggleMouseMode,
                  onToggleFullScreen: _toggleFullScreen,
                  onDisconnect: _disconnect,
                  isFullScreen: _isFullScreen,
                  onToggleOrientation: _toggleOrientation,
                  onOrientationMenu: _showOrientationMenu,
                  onToggleAudio: _toggleAudio,
                  audioEnabled: !AudioManager.instance.muted,
                ),
              ),
            ),
            
          // Fullscreen controls
          if (_isFullScreen) ...[
            // Display mode toggle button
            Positioned(
              top: 24,
              right: 88,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _cycleDisplayMode,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D).withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getDisplayModeIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Full screen exit button
            Positioned(
              top: 24,
              right: 24,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleFullScreen,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE60012).withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE60012).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fullscreen_exit,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemoteSurface() {
    final Widget content;

    if (_remoteStream != null) {
      // Use RepaintBoundary to prevent pointer events from triggering
      // unnecessary repaints of the entire widget tree
      content = RepaintBoundary(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            // Hide soft keyboard when user interacts with video surface
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            _focusNode.requestFocus();

            final viewSize = _getVideoSize();
            final geometry = _buildMouseGeometry(viewSize);
            _updatePointerInside(true);
            _recordPointerPosition(event, geometry);
            _mouseController?.onPointerDown(event, geometry);
          },
          onPointerUp: (event) {
            final viewSize = _getVideoSize();
            final geometry = _buildMouseGeometry(viewSize);
            _recordPointerPosition(event, geometry);
            _mouseController?.onPointerUp(event, geometry);
          },
          onPointerMove: (event) {
            // Throttle pointer events to reduce CPU/Network usage
            final now = DateTime.now();
            final timeSinceLastEvent =
                now.difference(_lastPointerEventTime).inMilliseconds;
            final throttleMs =
                _mouseMode == MouseMode.relative ? 0 : _pointerEventThrottleMs;
            if (throttleMs > 0 && timeSinceLastEvent < throttleMs) {
              return;
            }
            _lastPointerEventTime = now;

            final viewSize = _getVideoSize();
            final geometry = _buildMouseGeometry(viewSize);
            _recordPointerPosition(event, geometry);
            _mouseController?.onPointerMove(event, geometry);
          },
          onPointerHover: (event) {
            // Throttle pointer events
            final now = DateTime.now();
            final timeSinceLastEvent =
                now.difference(_lastPointerEventTime).inMilliseconds;
            final throttleMs =
                _mouseMode == MouseMode.relative ? 0 : _pointerEventThrottleMs;
            if (throttleMs > 0 && timeSinceLastEvent < throttleMs) {
              return;
            }
            _lastPointerEventTime = now;

            final viewSize = _getVideoSize();
            final geometry = _buildMouseGeometry(viewSize);
            _updatePointerInside(true);
            _recordPointerPosition(event, geometry);
            _mouseController?.onPointerHover(event, geometry);
          },
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _mouseController?.onPointerScroll(event);
            }
          },
          onPointerCancel: (event) {
            _mouseController?.onPointerCancel(event);
          },
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            skipTraversal: true,
            includeSemantics: false,
            onKeyEvent: (node, event) {
              final handled =
                  _keyboardController?.handleKeyEvent(event) ?? false;
              return handled ? KeyEventResult.handled : KeyEventResult.ignored;
            },
            child: MouseRegion(
              onEnter: (event) {
                final viewSize = _getVideoSize();
                final geometry = _buildMouseGeometry(viewSize);
                _updatePointerInside(true);
                _recordPointerPosition(event, geometry);
              },
              onExit: (event) {
                _updatePointerInside(false);
              },
              cursor: _shouldHideLocalCursor
                  ? SystemMouseCursors.none
                  : MouseCursor.defer,
              child: Container(
                key: _videoKey,
                color: Colors.black,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: _IsolatedVideoRenderer(
                        stream: _remoteStream!,
                        displayMode: _displayMode,
                        remoteVideoSize: _remoteVideoSize,
                        videoFilterQuality: _videoFilterQuality,
                        onVideoSizeChanged: _handleVideoSizeChanged,
                      ),
                    ),
                    // Audio renderer - MUST be visible on Windows for audio to play
                    // Positioned in bottom-right corner, nearly transparent
                    if (_audioRenderer != null && _remoteStream != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        width: 1,
                        height: 1,
                        child: Container(
                          color: Colors.transparent,
                          child: RTCVideoView(
                            _audioRenderer!.renderer,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                            mirror: false,
                          ),
                        ),
                      ),
                    if (_shouldShowRemoteCursor && _remoteCursorImage != null)
                      ValueListenableBuilder<Offset>(
                        valueListenable: _pointerPositionNotifier,
                        builder: (context, position, child) {
                          return Positioned(
                            left: position.dx - _cursorHotspot.dx,
                            top: position.dy - _cursorHotspot.dy,
                            child: child!,
                          );
                        },
                        child: RawImage(
                          image: _remoteCursorImage,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      content = SwitchLoadingScreen(
        statusMessage: _statusMessage,
        onCancel: _disconnect,
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: content),
        if (_showMetrics && _statsCollector != null)
          Positioned(
            top: 16,
            left: 16,
            child: MetricsOverlay(statsCollector: _statsCollector!),
          ),
        if (_currentNotification != null)
          SwitchNotification(
            key: ValueKey(_currentNotification!.message),
            message: _currentNotification!.message,
            type: _currentNotification!.type,
            onDismiss: () {
              setState(() {
                _currentNotification = null;
              });
            },
          ),
      ],
    );
  }

  _NotificationData? _currentNotification;

  void _showNotification(String message, {SwitchNotificationType type = SwitchNotificationType.info}) {
    setState(() {
      _currentNotification = _NotificationData(message, type);
    });
  }
}

class _NotificationData {
  final String message;
  final SwitchNotificationType type;

  _NotificationData(this.message, this.type);
}

/// Isolated video renderer widget that only rebuilds when video-specific properties change
class _IsolatedVideoRenderer extends StatefulWidget {
  const _IsolatedVideoRenderer({
    Key? key,
    required this.stream,
    required this.displayMode,
    required this.remoteVideoSize,
    required this.videoFilterQuality,
    required this.onVideoSizeChanged,
  }) : super(key: key);

  final MediaStream stream;
  final DisplayMode displayMode;
  final Size remoteVideoSize;
  final FilterQuality videoFilterQuality;
  final void Function(int width, int height) onVideoSizeChanged;

  @override
  State<_IsolatedVideoRenderer> createState() => _IsolatedVideoRendererState();
}

class _IsolatedVideoRendererState extends State<_IsolatedVideoRenderer> {
  bool _shouldForceMobileWideAspectRatio() {
    if (kIsWeb) {
      return false;
    }
    final platform = defaultTargetPlatform;
    return widget.displayMode == DisplayMode.fit &&
        (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.displayMode == DisplayMode.contain) {
      return RemoteMediaRenderer(
        stream: widget.stream,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
        filterQuality: widget.videoFilterQuality,
        onVideoSizeChanged: widget.onVideoSizeChanged,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_shouldForceMobileWideAspectRatio()) {
          final baseWidth = widget.remoteVideoSize.width > 0
              ? widget.remoteVideoSize.width
              : 1920.0;
          final baseHeight = widget.remoteVideoSize.height > 0
              ? widget.remoteVideoSize.height
              : 1080.0;

          final videoBox = baseWidth > 0 && baseHeight > 0
              ? SizedBox(
                  width: baseWidth,
                  height: baseHeight,
                  child: RemoteMediaRenderer(
                    stream: widget.stream,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    filterQuality: widget.videoFilterQuality,
                    onVideoSizeChanged: widget.onVideoSizeChanged,
                  ),
                )
              : RemoteMediaRenderer(
                  stream: widget.stream,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  filterQuality: widget.videoFilterQuality,
                  onVideoSizeChanged: widget.onVideoSizeChanged,
                );

          return Center(
            child: AspectRatio(
              aspectRatio: 20 / 9,
              child: Container(
                color: Colors.black,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: videoBox,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: widget.remoteVideoSize.width > 0
                  ? widget.remoteVideoSize.width
                  : 1920.0,
              height: widget.remoteVideoSize.height > 0
                  ? widget.remoteVideoSize.height
                  : 1080.0,
              child: RemoteMediaRenderer(
                stream: widget.stream,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                filterQuality: widget.videoFilterQuality,
                onVideoSizeChanged: widget.onVideoSizeChanged,
              ),
            ),
          ),
        );
      },
    );
  }
}
