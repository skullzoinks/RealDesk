import 'dart:convert';

/// SDP helper utilities.
class SdpUtils {
  const SdpUtils._();

  /// Reorders the payload list inside the first [mediaType] m-line so that all
  /// payloads belonging to [codec] appear first (while preserving RTX pairs)
  /// to help remote peers pick MediaCodec-friendly codecs.
  static String preferCodec({
    required String sdp,
    required String codec,
    required String mediaType,
  }) {
    if (sdp.isEmpty || codec.isEmpty || mediaType.isEmpty) {
      return sdp;
    }

    final lines = List<String>.from(const LineSplitter().convert(sdp));
    if (lines.isEmpty) {
      return sdp;
    }

    final mediaLineIndex = lines.indexWhere(
      (line) => line.startsWith('m=$mediaType '),
    );
    if (mediaLineIndex == -1) {
      return sdp;
    }

    final codecRegex = RegExp(
      '^a=rtpmap:(\\d+)\\s+${RegExp.escape(codec)}(?:/\\d+)?',
      caseSensitive: false,
    );
    final codecPayloads = <String>[];
    for (final line in lines) {
      final match = codecRegex.firstMatch(line);
      if (match != null) {
        codecPayloads.add(match.group(1)!);
      }
    }
    if (codecPayloads.isEmpty) {
      return sdp;
    }

    final fmtpRegex = RegExp(r'^a=fmtp:(\d+)\s+.*apt=(\d+)');
    final codecToRtx = <String, List<String>>{};
    for (final line in lines) {
      final match = fmtpRegex.firstMatch(line);
      if (match != null) {
        final rtxPt = match.group(1)!;
        final codecPt = match.group(2)!;
        codecToRtx.putIfAbsent(codecPt, () => <String>[]).add(rtxPt);
      }
    }

    final mediaLineParts = lines[mediaLineIndex].split(' ');
    if (mediaLineParts.length <= 3) {
      return sdp;
    }

    final header = mediaLineParts.sublist(0, 3);
    final payloads = mediaLineParts.sublist(3);

    final seen = <String>{};
    final reorderedPayloads = <String>[];
    void addPayload(String pt) {
      if (payloads.contains(pt) && seen.add(pt)) {
        reorderedPayloads.add(pt);
      }
    }

    for (final codecPt in codecPayloads) {
      addPayload(codecPt);
      final rtxList = codecToRtx[codecPt];
      if (rtxList != null) {
        for (final rtxPt in rtxList) {
          addPayload(rtxPt);
        }
      }
    }
    for (final pt in payloads) {
      addPayload(pt);
    }

    lines[mediaLineIndex] = [...header, ...reorderedPayloads].join(' ');

    final buffer = StringBuffer();
    for (final line in lines) {
      buffer
        ..write(line)
        ..write('\r\n');
    }
    return buffer.toString();
  }

  /// Applies multiple codec preferences sequentially so the first codec in
  /// [codecs] gets the highest priority, followed by the next entries.
  static String preferCodecs({
    required String sdp,
    required String mediaType,
    required List<String> codecs,
  }) {
    var updated = sdp;
    for (final codec in codecs.reversed) {
      if (codec.trim().isEmpty) continue;
      updated = preferCodec(
        sdp: updated,
        codec: codec,
        mediaType: mediaType,
      );
    }
    return updated;
  }

  /// Convenience helper that prioritizes H264 inside the video m-line.
  static String preferH264(String sdp) {
    return preferCodecs(
      sdp: sdp,
      mediaType: 'video',
      codecs: const ['H264'],
    );
  }
}
