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
  final String? _preferredVideoCodec;
  final Logger _logger;

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  RTCDataChannel? _dataChannelRt;
  RTCDataChannel? _dataChannelReliable;
  MediaStream? _localStream;
  final List<RTCRtpSender> _localSenders = [];
  bool _audioReceiverProvisioned = false;
  bool _isClosed = false;
  bool get _preferHardwareCodecs =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
  final _dataChannelController =
      StreamController<RTCDataChannelMessage>.broadcast();
  final _dataChannelStateController =
      StreamController<RTCDataChannelState>.broadcast();

  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<RTCIceCandidate> get iceCandidate => _iceCandidateController.stream;
  Stream<RTCPeerConnectionState> get connectionState =>
      _connectionStateController.stream;
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

    _isClosed = false;
    _peerConnection = await createPeerConnection(
      configuration,
      <String, dynamic>{},
    );
    await _ensureAudioReceiver();

    // Set up event handlers
    _peerConnection!.onTrack = _onTrack;
    _peerConnection!.onIceCandidate = _onIceCandidate;
    _peerConnection!.onConnectionState = _onConnectionState;
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
    _isClosed = false;
    _peerConnection = await createPeerConnection(
      configuration,
      <String, dynamic>{},
    );
    await _ensureAudioReceiver();
    _peerConnection!.onTrack = _onTrack;
    _peerConnection!.onIceCandidate = _onIceCandidate;
    _peerConnection!.onConnectionState = _onConnectionState;
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
    _logger.i('Received track: ${event.track.kind}');

    MediaStream? stream;
    if (event.streams.isNotEmpty) {
      stream = event.streams.first;
    } else {
      try {
        stream = await createLocalMediaStream('remote-${event.track.id}');
        await stream.addTrack(event.track);
      } catch (e) {
        _logger.w('Failed to create fallback stream: $e');
      }
    }

    if (stream != null && _canAddTo(_remoteStreamController)) {
      _remoteStreamController.add(stream);
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

  /// Close peer connection
  Future<void> close() async {
    _logger.i('Closing peer connection');
    _isClosed = true;

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
    _audioReceiverProvisioned = false;
  }

  /// Dispose resources
  void dispose() {
    _isClosed = true;
    close();
    _remoteStreamController.close();
    _iceCandidateController.close();
    _connectionStateController.close();
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
