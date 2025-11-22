import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

import '../settings/settings_model.dart';
import 'sdp_utils.dart';

/// WebRTC peer connection manager
class PeerManager {
  PeerManager({
    List<dynamic>? iceServers,
    String? preferredVideoCodec,
  })  : _iceServers = iceServers != null
            ? List<dynamic>.from(iceServers)
            : RealDeskSettings.defaultIceServers
                .map((server) => Map<String, dynamic>.from(server))
                .toList(),
        _preferredVideoCodec = preferredVideoCodec?.trim().toUpperCase(),
        _logger = Logger();

  final List<dynamic> _iceServers;
  String? _preferredVideoCodec;
  final Logger _logger;

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  RTCDataChannel? _dataChannelRt;
  RTCDataChannel? _dataChannelReliable;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<RTCRtpSender> _localSenders = [];
  bool _audioReceiverProvisioned = false;
  bool _isClosed = false;
  bool get _preferHardwareCodecs =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // ICE connection state management
  RTCIceConnectionState? _lastIceConnectionState;
  Timer? _iceRestartTimer;
  int _iceRestartAttempts = 0;
  static const int _maxIceRestartAttempts = 3;
  static const Duration _iceRestartDelay = Duration(seconds: 2);
  bool _isIceRestarting = false;

  static const Map<String, List<String>> _codecSynonyms = {
    'H264': ['H264', 'AVC'],
    'H265': ['H265', 'HEVC'],
    'VP8': ['VP8'],
    'VP9': ['VP9'],
    'AV1': ['AV1', 'AV1X'],
  };

  static const List<String> _androidHardwareCodecOrder = [
    'H265',
    'HEVC',
    'H264',
    'AVC',
    'VP9',
    'VP8',
    'AV1',
    'AV1X',
  ];

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _iceCandidateController = StreamController<RTCIceCandidate>.broadcast();
  final _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();
  final _iceConnectionStateController =
      StreamController<RTCIceConnectionState>.broadcast();
  final _dataChannelController =
      StreamController<RTCDataChannelMessage>.broadcast();
  final _dataChannelStateController =
      StreamController<RTCDataChannelState>.broadcast();

  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<RTCIceCandidate> get iceCandidate => _iceCandidateController.stream;
  Stream<RTCPeerConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<RTCIceConnectionState> get iceConnectionState =>
      _iceConnectionStateController.stream;
  Stream<RTCDataChannelMessage> get dataChannelMessage =>
      _dataChannelController.stream;
  Stream<RTCDataChannelState> get dataChannelState =>
      _dataChannelStateController.stream;

  RTCPeerConnection? get peerConnection => _peerConnection;
  RTCDataChannel? get dataChannel => _dataChannel;
  RTCDataChannel? get rtChannel => _dataChannelRt;
  RTCDataChannel? get reliableChannel => _dataChannelReliable;
  MediaStream? get localStream => _localStream;

  /// Create peer connection
  Future<void> initializePeerConnection() async {
    if (_peerConnection != null) {
      _logger.w('Peer connection already exists');
      return;
    }

    _logger.i('Creating peer connection');

    final configuration = <String, dynamic>{
      'sdpSemantics': 'unified-plan',
      'iceServers': _iceServers,
    };

    // Enable hardware acceleration on macOS
    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _isClosed = false;
    _peerConnection = await createPeerConnection(
      configuration,
      constraints,
    );
    await _ensureAudioReceiver();

    // Set up event handlers
    _peerConnection!.onTrack = _onTrack;
    _peerConnection!.onIceCandidate = _onIceCandidate;
    _peerConnection!.onConnectionState = _onConnectionState;
    _peerConnection!.onIceConnectionState = _onIceConnectionState;
    _peerConnection!.onDataChannel = _onDataChannel;

    _logger.i('Peer connection created');
  }

  /// Create peer connection with custom ICE servers (e.g., from Ayame accept)
  Future<void> initializePeerConnectionWithIceServers(
    List<dynamic> iceServers,
  ) async {
    if (_peerConnection != null) {
      _logger.w('Peer connection already exists');
      return;
    }
    _logger.i('Creating peer connection (custom ICE)');
    final configuration = <String, dynamic>{
      'sdpSemantics': 'unified-plan',
      'iceServers': iceServers,
    };

    // Enable hardware acceleration on macOS
    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _isClosed = false;
    _peerConnection = await createPeerConnection(
      configuration,
      constraints,
    );
    await _ensureAudioReceiver();
    _peerConnection!.onTrack = _onTrack;
    _peerConnection!.onIceCandidate = _onIceCandidate;
    _peerConnection!.onConnectionState = _onConnectionState;
    _peerConnection!.onIceConnectionState = _onIceConnectionState;
    _peerConnection!.onDataChannel = _onDataChannel;
  }

  /// Create data channel
  Future<RTCDataChannel> createDataChannel(
    String label, {
    bool ordered = false,
    int maxRetransmits = 0,
  }) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }

    _logger.i('Creating data channel: $label');

    final dataChannelDict = RTCDataChannelInit();
    dataChannelDict.ordered = ordered;
    dataChannelDict.maxRetransmits = maxRetransmits;

    _dataChannel = await _peerConnection!.createDataChannel(
      label,
      dataChannelDict,
    );

    _setupDataChannelHandlers(_dataChannel!);

    return _dataChannel!;
  }

  /// Create two input channels: input-rt (unreliable) and input-reliable
  Future<void> createInputChannels() async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }
    // Unreliable, unordered real-time channel
    final rtInit = RTCDataChannelInit()
      ..ordered = false
      ..maxRetransmits = 0;
    _dataChannelRt = await _peerConnection!.createDataChannel(
      'input-rt',
      rtInit,
    );
    _setupDataChannelHandlers(_dataChannelRt!);

    // Reliable channel
    final reliableInit = RTCDataChannelInit()..ordered = true;
    _dataChannelReliable = await _peerConnection!.createDataChannel(
      'input-reliable',
      reliableInit,
    );
    _setupDataChannelHandlers(_dataChannelReliable!);

    // Keep the last created as default for backwards usage
    _dataChannel = _dataChannelRt;
  }

  /// Create offer
  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }

    _logger.i('Creating offer');

    var offer = await _peerConnection!.createOffer({
      'offerToReceiveVideo': 1,
      'offerToReceiveAudio': 1,
      'mandatory': {'OfferToReceiveVideo': true, 'OfferToReceiveAudio': true},
    });

    offer = _applyLocalCodecPreferences(offer);
    await _peerConnection!.setLocalDescription(offer);

    return offer;
  }

  /// Create answer
  Future<RTCSessionDescription> createAnswer() async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }

    _logger.i('Creating answer');

    var answer = await _peerConnection!.createAnswer();
    answer = _applyLocalCodecPreferences(answer);
    await _peerConnection!.setLocalDescription(answer);

    return answer;
  }

  /// Set remote description
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }

    _logger.i('Setting remote description: ${description.type}');
    await _peerConnection!.setRemoteDescription(description);
  }

  /// Add ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }

    _logger.d('Adding ICE candidate');
    await _peerConnection!.addCandidate(candidate);
  }

  /// Send data through data channel
  void sendData(String data) {
    if (_dataChannel == null) {
      _logger.w('Data channel not available');
      return;
    }

    final message = RTCDataChannelMessage(data);
    _dataChannel!.send(message);
  }

  /// Attach (or replace) the local media stream that should be published.
  Future<void> setLocalMediaStream(MediaStream? stream) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }

    await _removeLocalSenders();
    _localStream = stream;

    if (stream == null) {
      return;
    }

    final tracks = <MediaStreamTrack>[
      ...stream.getAudioTracks(),
      ...stream.getVideoTracks(),
    ];

    for (final track in tracks) {
      try {
        final sender = await _peerConnection!.addTrack(track, stream);
        _localSenders.add(sender);
      } catch (e, stackTrace) {
        _logger.e(
          'Failed to add local track ${track.id}: $e',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    }
  }

  /// Handle incoming track
  void _onTrack(RTCTrackEvent event) async {
    _logger.i('Received track: ${event.track.kind}, id=${event.track.id}, '
        'enabled=${event.track.enabled}');

    // Use the stream from the event if available, otherwise create/use our accumulated stream
    if (event.streams.isNotEmpty) {
      final incomingStream = event.streams.first;

      // If we don't have a remote stream yet, use this one
      if (_remoteStream == null) {
        _remoteStream = incomingStream;
        _logger.i('Using new remote stream: ${_remoteStream!.id}');
        if (_canAddTo(_remoteStreamController)) {
          _remoteStreamController.add(_remoteStream!);
        }
      } else if (_remoteStream!.id != incomingStream.id) {
        // Different stream ID - this is a completely new stream (e.g., after reconnection)
        _logger.i(
          'Replacing stream ${_remoteStream!.id} with new stream ${incomingStream.id}',
        );
        _remoteStream = incomingStream;
        // Always emit on stream replacement to force renderer update
        if (_canAddTo(_remoteStreamController)) {
          _remoteStreamController.add(_remoteStream!);
        }
      } else {
        // Same stream ID - track was added to existing stream
        // Force emit to ensure renderer picks up new tracks (important for reconnection)
        _logger.i(
          'Track ${event.track.kind} added to existing stream ${_remoteStream!.id}',
        );
        if (_canAddTo(_remoteStreamController)) {
          _remoteStreamController.add(_remoteStream!);
        }
      }
    } else {
      // No stream provided, create one and accumulate tracks
      if (_remoteStream == null) {
        try {
          _remoteStream = await createLocalMediaStream('remote-stream');
          _logger.i('Created new remote stream: ${_remoteStream!.id}');
        } catch (e) {
          _logger.e('Failed to create remote stream: $e');
          return;
        }
      }

      try {
        await _remoteStream!.addTrack(event.track);
        _logger.i('Added ${event.track.kind} track to remote stream');
        if (_canAddTo(_remoteStreamController)) {
          _remoteStreamController.add(_remoteStream!);
        }
      } catch (e) {
        _logger.w('Failed to add track to stream: $e');
      }
    }

    // Log current stream state for debugging
    if (_remoteStream != null) {
      _logger.i(
        'Remote stream state: ${_remoteStream!.getVideoTracks().length} video, '
        '${_remoteStream!.getAudioTracks().length} audio tracks',
      );
    }
  }

  /// Handle ICE candidate
  void _onIceCandidate(RTCIceCandidate candidate) {
    _logger.d('ICE candidate generated');
    if (_canAddTo(_iceCandidateController)) {
      _iceCandidateController.add(candidate);
    }
  }

  /// Handle connection state change
  void _onConnectionState(RTCPeerConnectionState state) {
    _logger.i('Connection state changed: $state');
    if (_canAddTo(_connectionStateController)) {
      _connectionStateController.add(state);
    }
  }

  /// Handle ICE connection state change
  void _onIceConnectionState(RTCIceConnectionState state) {
    _logger.i('ICE connection state changed: $state');
    _lastIceConnectionState = state;

    if (_canAddTo(_iceConnectionStateController)) {
      _iceConnectionStateController.add(state);
    }

    // Handle disconnection with automatic ICE restart
    if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      _scheduleIceRestart();
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      _handleIceConnectionFailed();
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      // Connection restored, reset counters
      _cancelIceRestart();
      _iceRestartAttempts = 0;
    }
  }

  /// Schedule an ICE restart after a delay
  void _scheduleIceRestart() {
    if (_isIceRestarting || _isClosed) {
      return;
    }

    // Cancel any existing timer
    _iceRestartTimer?.cancel();

    if (_iceRestartAttempts >= _maxIceRestartAttempts) {
      _logger.w(
        'Max ICE restart attempts ($_maxIceRestartAttempts) reached, '
        'connection may need full renegotiation',
      );
      return;
    }

    _logger.i(
      'Scheduling ICE restart in ${_iceRestartDelay.inSeconds}s '
      '(attempt ${_iceRestartAttempts + 1}/$_maxIceRestartAttempts)',
    );

    _iceRestartTimer = Timer(_iceRestartDelay, () {
      if (!_isClosed &&
          _lastIceConnectionState ==
              RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _performIceRestart();
      }
    });
  }

  /// Cancel scheduled ICE restart
  void _cancelIceRestart() {
    _iceRestartTimer?.cancel();
    _iceRestartTimer = null;
    if (_isIceRestarting) {
      _logger.i('ICE restart cancelled - connection restored');
      _isIceRestarting = false;
    }
  }

  /// Perform ICE restart to recover connection
  Future<void> _performIceRestart() async {
    if (_peerConnection == null || _isClosed || _isIceRestarting) {
      return;
    }

    _isIceRestarting = true;
    _iceRestartAttempts++;

    try {
      _logger.i('Performing ICE restart (attempt $_iceRestartAttempts)...');

      // Create new offer with iceRestart flag
      final offer = await _peerConnection!.createOffer({
        'iceRestart': true,
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': 1,
      });

      await _peerConnection!.setLocalDescription(offer);

      _logger.i('ICE restart offer created, local description set');
      // Note: The offer needs to be sent through signaling
      // This will be handled by the session page
    } catch (e, stackTrace) {
      _logger.e(
        'ICE restart failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isIceRestarting = false;
    }
  }

  /// Handle ICE connection failure
  void _handleIceConnectionFailed() {
    _logger.w(
      'ICE connection failed after $_iceRestartAttempts restart attempts',
    );
    _cancelIceRestart();
    // Connection state will propagate to session page for user notification
  }

  /// Manually trigger ICE restart (can be called from UI)
  Future<RTCSessionDescription?> restartIce() async {
    if (_peerConnection == null || _isClosed) {
      _logger.w('Cannot restart ICE: peer connection not available');
      return null;
    }

    try {
      _logger.i('Manual ICE restart requested');
      _cancelIceRestart();
      _iceRestartAttempts = 0;

      var offer = await _peerConnection!.createOffer({
        'iceRestart': true,
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': 1,
      });

      offer = _applyLocalCodecPreferences(offer);
      await _peerConnection!.setLocalDescription(offer);

      _logger.i('ICE restart offer created successfully');
      return offer;
    } catch (e, stackTrace) {
      _logger.e(
        'Manual ICE restart failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Handle data channel
  void _onDataChannel(RTCDataChannel dataChannel) {
    _logger.i('Data channel received: ${dataChannel.label}');
    _dataChannel = dataChannel;
    if (dataChannel.label == 'input-rt') {
      _dataChannelRt = dataChannel;
    } else if (dataChannel.label == 'input-reliable') {
      _dataChannelReliable = dataChannel;
    }
    _setupDataChannelHandlers(dataChannel);
  }

  /// Setup data channel handlers
  void _setupDataChannelHandlers(RTCDataChannel dataChannel) {
    dataChannel.onMessage = (RTCDataChannelMessage message) {
      if (_canAddTo(_dataChannelController)) {
        _dataChannelController.add(message);
      }
    };

    dataChannel.onDataChannelState = (RTCDataChannelState state) {
      _logger.i('Data channel state: $state');
      if (_canAddTo(_dataChannelStateController)) {
        _dataChannelStateController.add(state);
      }
    };
  }

  /// Get statistics
  Future<List<StatsReport>> getStats() async {
    if (_peerConnection == null) {
      return [];
    }

    return await _peerConnection!.getStats();
  }

  /// Update preferred video codec and optionally renegotiate
  Future<void> setPreferredCodec(String? codec,
      {bool renegotiate = false}) async {
    final normalized = codec?.trim().toUpperCase();
    if (_preferredVideoCodec == normalized) {
      _logger.i('Codec already set to $normalized, no change needed');
      return;
    }

    _preferredVideoCodec = normalized;
    _logger.i('Updated preferred video codec to: $_preferredVideoCodec');

    if (renegotiate && _peerConnection != null) {
      await this.renegotiate();
    }
  }

  /// Renegotiate the connection with updated codec preferences
  /// This creates a new offer and applies codec preferences
  Future<void> renegotiate() async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }

    final signalingState = await _peerConnection!.getSignalingState();
    if (signalingState != RTCSignalingState.RTCSignalingStateStable) {
      _logger.w('Cannot renegotiate: signaling state is $signalingState');
      throw Exception('Cannot renegotiate: connection not in stable state');
    }

    _logger.i(
        'Starting renegotiation with codec preference: $_preferredVideoCodec');

    try {
      // Create new offer with updated codec preferences
      var offer = await _peerConnection!.createOffer({
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': 1,
        'mandatory': {'OfferToReceiveVideo': true, 'OfferToReceiveAudio': true},
      });

      offer = _applyLocalCodecPreferences(offer);
      await _peerConnection!.setLocalDescription(offer);

      _logger.i('Renegotiation offer created, waiting for answer');
      // Note: The caller must send this offer through signaling and handle the answer
    } catch (e, stackTrace) {
      _logger.e(
        'Renegotiation failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Close peer connection
  Future<void> close() async {
    _logger.i('Closing peer connection');
    _isClosed = true;

    // Cancel any pending ICE restart
    _cancelIceRestart();
    _iceRestartAttempts = 0;

    await _dataChannel?.close();
    _dataChannel = null;
    await _dataChannelRt?.close();
    _dataChannelRt = null;
    await _dataChannelReliable?.close();
    _dataChannelReliable = null;

    if (_peerConnection != null) {
      _peerConnection!.onTrack = null;
      _peerConnection!.onIceCandidate = null;
      _peerConnection!.onConnectionState = null;
      _peerConnection!.onDataChannel = null;
    }
    await _removeLocalSenders();
    await _peerConnection?.close();
    _peerConnection = null;
    _remoteStream = null;
    _audioReceiverProvisioned = false;
  }

  /// Dispose resources
  void dispose() {
    _isClosed = true;
    close();
    _remoteStreamController.close();
    _iceCandidateController.close();
    _connectionStateController.close();
    _iceConnectionStateController.close();
    _dataChannelController.close();
    _dataChannelStateController.close();
  }

  bool _canAddTo(StreamController controller) {
    return !_isClosed && !controller.isClosed;
  }

  Future<void> _removeLocalSenders() async {
    if (_localSenders.isEmpty) {
      _localStream = null;
      return;
    }

    final senders = List<RTCRtpSender>.from(_localSenders);
    _localSenders.clear();

    for (final sender in senders) {
      try {
        await _peerConnection?.removeTrack(sender);
      } catch (e, stackTrace) {
        _logger.w(
          'Failed to remove local sender: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    _localStream = null;
  }

  Future<void> _ensureAudioReceiver() async {
    if (_peerConnection == null || _audioReceiverProvisioned) {
      return;
    }
    try {
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.RecvOnly,
        ),
      );
      _audioReceiverProvisioned = true;
      _logger.i('Provisioned recvonly audio transceiver for remote playback');
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to provision audio transceiver: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  RTCSessionDescription _applyLocalCodecPreferences(
    RTCSessionDescription description,
  ) {
    if (description.sdp == null) {
      return description;
    }

    final originalSdp = description.sdp!;
    final codecChain = _codecPreferenceChain();
    if (codecChain.isEmpty) {
      return description;
    }

    final updated = SdpUtils.preferCodecs(
      sdp: originalSdp,
      mediaType: 'video',
      codecs: codecChain,
    );
    if (updated == originalSdp) {
      _logger.w(
        'Preferred codecs $codecChain not found in remote SDP; using sender defaults',
      );
      return description;
    }

    _logger.i(
      'Applied video codec preference order: ${codecChain.join(' > ')}',
    );
    return RTCSessionDescription(updated, description.type);
  }

  List<String> _codecPreferenceChain() {
    final ordered = <String>[];
    final canonicalPreferred = _canonicalCodecName(_preferredVideoCodec);
    if (canonicalPreferred != null) {
      ordered.addAll(
        _codecSynonyms[canonicalPreferred] ?? [canonicalPreferred],
      );
    }
    if (_preferHardwareCodecs) {
      ordered.addAll(_androidHardwareCodecOrder);
    }
    return _dedupePreservingOrder(ordered);
  }

  String? _canonicalCodecName(String? codec) {
    if (codec == null || codec.isEmpty) {
      return null;
    }
    final upper = codec.toUpperCase();
    for (final entry in _codecSynonyms.entries) {
      if (entry.value.contains(upper)) {
        return entry.key;
      }
    }
    return upper;
  }

  List<String> _dedupePreservingOrder(List<String> codecs) {
    final seen = <String>{};
    final result = <String>[];
    for (final codec in codecs) {
      if (codec.isEmpty) continue;
      final upper = codec.toUpperCase();
      if (seen.add(upper)) {
        result.add(upper);
      }
    }
    return result;
  }
}
