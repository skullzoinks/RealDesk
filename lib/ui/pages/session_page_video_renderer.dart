
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
