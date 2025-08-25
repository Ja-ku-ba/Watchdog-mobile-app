import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoPage extends StatefulWidget {
  const FullscreenVideoPage({super.key});

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  Timer? _hideTimer;
  // Timer? _bufferCheckTimer;
  // Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    _controller = args['controller'] as VideoPlayerController;
  }

  void _showControlers() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GestureDetector(
      onTap: _showControlers,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 10,
                right: 10,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    final current = _controller!.value.position;
                                    final newPos =
                                        current - const Duration(seconds: 10);
                                    _controller!.seekTo(
                                      newPos.isNegative
                                          ? Duration.zero
                                          : newPos,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    _controller!.value.isPlaying
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller!.value.isPlaying
                                          ? _controller!.pause()
                                          : _controller!.play();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    final current = _controller!.value.position;
                                    final newPos =
                                        current + const Duration(seconds: 10);
                                    _controller!.seekTo(newPos);
                                  },
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 11,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.fullscreen_exit,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.red,
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
