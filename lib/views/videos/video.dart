import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:watchdog/layouts/base/loged_in_layout.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchdog/models/video.dart';
import 'package:watchdog/components/loading.dart';

class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    if (args == null || args['video'] == null) {
      return AppLayout(
        child: const SafeArea(
          child: Center(
            child: Text(
              'Błąd: Brak danych video',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    final video = args['video'] as Video;

    return AppLayout(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: VideoStreamer(videoObj: video),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoStreamer extends StatefulWidget {
  final Video videoObj;

  const VideoStreamer({super.key, required this.videoObj});

  @override
  State<VideoStreamer> createState() => _VideoStreamerState();
}

class _VideoStreamerState extends State<VideoStreamer> {
  late Video videoObj;
  VideoPlayerController? _controller;
  String _errorMessage = '';
  bool _isLoading = true;
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _bufferCheckTimer;
  Duration _lastPosition = Duration.zero;
  int _bufferCheckCount = 0;
  static final String baseUrl = dotenv.env['BASE_URL']!;

  @override
  void initState() {
    super.initState();
    videoObj = widget.videoObj;
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('Brak tokenu autoryzacji');
      }

      await _controller?.dispose();

      _controller = VideoPlayerController.networkUrl(
        Uri.parse('${baseUrl}/videos/${videoObj.hash}'),
        httpHeaders: {
          'Authorization': 'Bearer $token',
          'Accept': 'video/*',
        },
      );
      VideoPlayerManager().registerController(_controller!);

      _controller!.addListener(_videoPlayerListener);

      await _controller!.initialize();

      if (mounted) {
        setState(() => _isLoading = false);
        await _controller!.play();
        _startBufferMonitor();
      }
    } on SocketException catch (e) {
      _handleError('Błąd połączenia sieciowego: ${e.message}');
    } on FormatException catch (e) {
      _handleError('Nieprawidłowy format video: ${e.message}');
    } catch (error) {
      _handleError('Nie udało się załadować wideo: $error');
    }
  }

  void _videoPlayerListener() {
    if (_controller == null) return;
    if (mounted) setState(() {});
    final value = _controller!.value;

    if (value.hasError && mounted) {
      _handleError('Błąd odtwarzania: ${value.errorDescription ?? 'Nieznany błąd'}');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });

    _bufferCheckTimer?.cancel();
  }

  void _startBufferMonitor() {
    _bufferCheckTimer?.cancel();
    _bufferCheckCount = 0;

    _bufferCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_controller == null || !_controller!.value.isInitialized || !mounted) {
        timer.cancel();
        return;
      }

      final currentValue = _controller!.value;
      final currentPos = currentValue.position;

      if (currentValue.isPlaying && currentPos == _lastPosition) {
        _bufferCheckCount++;

        if (_bufferCheckCount >= 3 && !_isLoading) {
          setState(() => _isLoading = true);
        }
      } else {
        _bufferCheckCount = 0;
        _lastPosition = currentPos;

        if (_isLoading && currentValue.isPlaying) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  void _toggleControls() {
    if (!mounted) return;

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
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _seekVideo(Duration offset) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final currentPosition = _controller!.value.position;
    final duration = _controller!.value.duration;
    final newPosition = currentPosition + offset;

    Duration targetPosition;
    if (newPosition.isNegative) {
      targetPosition = Duration.zero;
    } else if (newPosition > duration) {
      targetPosition = duration;
    } else {
      targetPosition = newPosition;
    }

    _controller!.seekTo(targetPosition);
  }

  String formatDate(DateTime date) {
    return DateFormat("HH:mm, dd.MM.yyyy").format(date);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}h ${twoDigits(minutes)}min ${twoDigits(seconds)}s';
    } else if (minutes > 0) {
      return '${twoDigits(minutes)}min ${twoDigits(seconds)}s';
    } else {
      return '${twoDigits(seconds)}s';
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _bufferCheckTimer?.cancel();

    if (_controller != null) {
      VideoPlayerManager().unregisterController(_controller!);
      _controller!.removeListener(_videoPlayerListener);
      _controller!.pause();
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _controller == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingCircle(size: 45),
            SizedBox(height: 16),
            Text(
              'Ładowanie nagrania...',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Błąd ładowania wideo',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeVideoPlayer,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: LoadingCircle(size: 45),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _toggleControls,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),

                if (_isLoading)
                  const LoadingCircle(size: 50),

                if (_showControls)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _seekVideo(const Duration(seconds: -10)),
                                      icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                                    ),
                                    IconButton(
                                      // onPressed: _togglePlayPause,
                                      onPressed: () => {
                                        _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()
                                      },
                                      icon: Icon(
                                        _controller!.value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _seekVideo(const Duration(seconds: 10)),
                                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.only(top: 10),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    onPressed: () {
                                      if (_controller != null && _controller!.value.isInitialized) {
                                        Navigator.of(context).pushNamed(
                                          '/video/full-mode',
                                          arguments: {'controller': _controller},
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.red,
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView(
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.video_library),
                  title: Text(
                    '${formatDate(videoObj.recordedAt)}, ${videoObj.camera}',
                  ),
                  subtitle: Text(
                    '${videoObj.type}, długość nagrania: ${formatDuration(videoObj.recordLength)}',
                  ),
                ),
              ),
              // const SizedBox(height: 8),
              // Card(
              //   child: ListTile(
              //     leading: const Icon(Icons.info),
              //     title: const Text('Informacje o video'),
              //     subtitle: Text(
              //       'Rozdzielczość: ${_controller?.value.size.width.toInt()}x${_controller?.value.size.height.toInt()}\n'
              //           'Długość: ${_formatDuration(_controller?.value.duration ?? Duration.zero)}',
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}