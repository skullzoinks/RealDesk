import 'package:flutter_test/flutter_test.dart';

import 'package:realdesk/webrtc/sdp_utils.dart';

void main() {
  test('preferH264 reorders payloads and keeps RTX pairs', () {
    const originalSdp = '''
v=0
o=- 46117324 2 IN IP4 127.0.0.1
s=-
t=0 0
m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99
a=rtpmap:96 VP8/90000
a=rtpmap:97 rtx/90000
a=fmtp:97 apt=96
a=rtpmap:98 H264/90000
a=fmtp:98 profile-level-id=42e01f;packetization-mode=1
a=rtpmap:99 rtx/90000
a=fmtp:99 apt=98
''';

    final updated = SdpUtils.preferH264(originalSdp);
    final videoLine = updated
        .split(RegExp(r'\r\n|\n|\r'))
        .firstWhere((line) => line.startsWith('m=video'));

    expect(
      videoLine.trim(),
      'm=video 9 UDP/TLS/RTP/SAVPF 98 99 96 97',
    );
  });

  test('preferCodecs applies ordered preferences with synonyms', () {
    const originalSdp = '''
v=0
m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100
a=rtpmap:96 VP8/90000
a=rtpmap:97 VP9/90000
a=rtpmap:98 H264/90000
a=rtpmap:99 AV1X/90000
a=rtpmap:100 H265/90000
''';

    final updated = SdpUtils.preferCodecs(
      sdp: originalSdp,
      mediaType: 'video',
      codecs: const ['AV1X', 'H265', 'VP9'],
    );

    final videoLine = updated
        .split(RegExp(r'\r\n|\n|\r'))
        .firstWhere((line) => line.startsWith('m=video'));

    expect(
      videoLine.trim(),
      'm=video 9 UDP/TLS/RTP/SAVPF 99 100 97 96 98',
    );
  });
}
