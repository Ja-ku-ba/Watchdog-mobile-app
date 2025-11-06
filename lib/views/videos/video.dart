import 'dart:async';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watchdog/layouts/base/loged_in_layout.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk_video;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchdog/models/video.dart';

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
          children: [Expanded(child: VideoStreamer(videoObj: video))],
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
  Player? _player;
  mk_video.VideoController? _controller;
  bool _showControls = true;
  bool _isLoading = true;
  String vpnRtspUrl = '';
  String? _errorMessage;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    videoObj = widget.videoObj;
    vpnRtspUrl = videoObj.url;
    _initializePlayer();
  }

  void _initializePlayer() {
    _disposePlayer();

    _player = Player(
      configuration: PlayerConfiguration(
        logLevel: MPVLogLevel.debug,
        vo: 'mediacodec_embed',
        bufferSize: 32 * 1024 * 1024,
      ),
    );

    _controller = mk_video.VideoController(_player!);
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (!mounted || _player == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('Brak tokenu autoryzacji');
      }

      final rtspUrl = vpnRtspUrl;
      final media = Media(
        rtspUrl,
        extras: {
          'rtsp_transport': 'tcp',
          'network-caching': '2000',
          'rtsp-timeout': '10',
        },
      );

      await _player!
          .open(media, play: true)
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Przekroczono czas oczekiwania na połączenie',
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      _handleError('Nie udało się załadować wideo: $error');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    }
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

  String formatDate(DateTime date) {
    return DateFormat("HH:mm, dd.MM.yyyy").format(date);
  }

  Future<void> _retryConnection() async {
    _initializePlayer();
  }

  void _disposePlayer() {
    _hideTimer?.cancel();
    _player?.dispose();
    _player = null;
    _controller = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleControls,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _isLoading
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Ładowanie strumienia...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                        : _errorMessage != null
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _retryConnection,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Spróbuj ponownie'),
                            ),
                          ],
                        ),
                      ),
                    )
                        : _controller != null
                        ? mk_video.Video(
                      controller: _controller!,
                      // Wymuś sprzętowe renderowanie
                      fill: Colors.black,
                    )
                        : const Center(
                      child: Text(
                        'Brak kontrolera video',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (videoObj.type != null && videoObj.type!.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.video_library),
              title: Text('${videoObj.recordedAt != null ? formatDate(videoObj.recordedAt!) : ''} ${videoObj.camera}'),              subtitle: Text(videoObj.type ?? 'brak danych'),
            ),
          ),
      ],
    );
  }
}