import 'package:flutter/material.dart';
import 'package:watchdog/layouts/base/loged_in_layout.dart';
import 'package:intl/intl.dart';
import 'package:watchdog/utils/request.dart';
import 'package:watchdog/models/video.dart';
import 'package:watchdog/components/loading.dart';
import 'dart:typed_data';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  List<Video> videos = [];

  // int _page = 0;
  // final int _limit = 20;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMore();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    final client = RequestClient();
    await client.initialize();

    try {
      final response = await client.get('/videos/get-videos');
      videos.addAll(
        (response.data as List).map((json) => Video.fromJson(json)).toList(),
      );
    } catch (e) {
      print("Błąd podczas ładowania: $e");
    } finally {
      setState(() => _isLoading = false);
    }

    setState(() {
      // _page++;
      _isLoading = false;
    });
  }

  Future<Uint8List> downloadThumbnail(String hash) async {
    final client = RequestClient();
    await client.initialize();
    return await client.getImage('/videos/thumbnail/$hash');
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

  @override
  Widget build(BuildContext context) {
    // WidgetsFlutterBinding.ensureInitialized();`
    return AppLayout(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: videos.length + 1,
                itemBuilder: (context, index) {
                  if (index == videos.length) {
                    return _isLoading
                      ? Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: LoadingCircle(size: 40,),
                        ),
                      )
                      : SizedBox();
                  }
                  return Container(
                    child: Column(
                      children: [
                        ListTile(
                          isThreeLine: true,
                          leading: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 80,
                              minHeight: 50,
                              maxWidth: 100,
                              maxHeight: 100,
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: FutureBuilder<Uint8List>(
                                future: downloadThumbnail(videos[index].hash),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const LoadingCircle(size: 40,);
                                  } else if (snapshot.hasError) {
                                    return const Icon(Icons.error);
                                  } else {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          title: Text(
                            '${formatDate(videos[index].recordedAt)}, ${videos[index].camera}',
                          ),
                          subtitle: Text(
                            '${videos[index].type}, długość nagrania: ${formatDuration(videos[index].recordLength)}',
                            // '${videos[index].type}, długość nagrania: ${formatDuration(videos[index].recordLength)}, hash:${videos[index].hash}',
                          ),
                          onTap: () => {
                            Navigator.of(context).pushReplacementNamed(
                              '/video',
                              arguments: {'video': videos[index]},
                            ),
                          },
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey,),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}













































// class VideoStreamer extends StatefulWidget {
//   const VideoStreamer({super.key});
//
//   @override
//   State<VideoStreamer> createState() => _VideoStreamerState();
// }
//
// class _VideoStreamerState extends State<VideoStreamer> {
//   VideoPlayerController? _controller;
//   String _errorMessage = '';
//   bool _isLoading = true;
//
//   Use the correct filename that works in your browser
// final String videoUrl = fuckingUrl;
//
// void testRequest() async {
//   try {
//     print('Testing URL: $videoUrl');
//     final response = await http.head(
//       Uri.parse(videoUrl),
//     ); // Use HEAD to test without downloading
//     print('Status code: ${response.statusCode}');
//     print('Content-Type: ${response.headers['content-type']}');
//     print('Content-Length: ${response.headers['content-length']}');
//
//     if (response.statusCode == 200 || response.statusCode == 206) {
//       print('URL is accessible');
//     } else {
//       print('URL returned error: ${response.statusCode}');
//       setState(() {
//         _errorMessage = 'Server returned ${response.statusCode}';
//       });
//     }
//   } catch (e) {
//     print('Error during http test: $e');
//     setState(() {
//       _errorMessage = 'Network error: $e';
//     });
//   }
// }
//
// @override
// void initState() {
//   super.initState();
//   testRequest();
//   initializeVideoPlayer();
// }
//
// void initializeVideoPlayer() async {
//   try {
//     _controller = VideoPlayerController.network(videoUrl);
//
//     await _controller!.initialize();
//
//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   } catch (error) {
//     print('Video initialization error: $error');
//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = 'Failed to load video.dart: $error';
//       });
//     }
//   }
// }
//
// @override
// void dispose() {
//   _controller?.dispose();
//   super.dispose();
// }
//
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: Colors.black,
//     body: Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (_isLoading)
//             Column(
//               children: [
//                 CircularProgressIndicator(color: Colors.white),
//                 SizedBox(height: 16),
//                 Text(
//                   'Loading video.dart...',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ],
//             )
//           else if (_errorMessage.isNotEmpty)
//             Padding(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Icon(Icons.error_outline, color: Colors.red, size: 64),
//                   SizedBox(height: 16),
//                   Text(
//                     'Error loading video.dart',
//                     style: TextStyle(
//                       color: Colors.red,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     _errorMessage,
//                     style: TextStyle(color: Colors.white),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         _errorMessage = '';
//                         _isLoading = true;
//                       });
//                       initializeVideoPlayer();
//                     },
//                     child: Text('Retry'),
//                   ),
//                 ],
//               ),
//             )
//           else if (_controller != null && _controller!.value.isInitialized)
//             Expanded(
//               child: Column(
//                 children: [
//                   Expanded(
//                     child: AspectRatio(
//                       aspectRatio: _controller!.value.aspectRatio,
//                       child: VideoPlayer(_controller!),
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   VideoProgressIndicator(
//                     _controller!,
//                     allowScrubbing: true,
//                     colors: VideoProgressColors(
//                       playedColor: Colors.blue,
//                       bufferedColor: Colors.grey,
//                       backgroundColor: Colors.black,
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       IconButton(
//                         onPressed: () {
//                           Implement previous video functionality
// },
// icon: Icon(
//   Icons.skip_previous,
//   color: Colors.white,
//   size: 32,
// ),
// ),
// SizedBox(width: 16),
// IconButton(
//   onPressed: () {
//     setState(() {
//       _controller!.value.isPlaying
//           ? _controller!.pause()
//           : _controller!.play();
//     });
//   },
//   icon: Icon(
//     _controller!.value.isPlaying
//         ? Icons.pause_circle_filled
//         : Icons.play_circle_filled,
//     color: Colors.white,
//     size: 48,
//   ),
// ),
// SizedBox(width: 16),
// IconButton(
//   onPressed: () {
//     Implement next video functionality
// },
// icon: Icon(
//   Icons.skip_next,
//   color: Colors.white,
//   size: 32,
// ),
// ),
// ],
// ),
// SizedBox(height: 16),
// ],
// ),
// ),
// ],
// ),
// ),
// );
// }
// }
//
// class NetworkTestWidget extends StatefulWidget {
//   @override
//   _NetworkTestWidgetState createState() => _NetworkTestWidgetState();
// }
//
// class _NetworkTestWidgetState extends State<NetworkTestWidget> {
//   String _testResults = '';
//   bool _isLoading = false;
//
//   Future<void> runNetworkTests() async {
//     setState(() {
//       _isLoading = true;
//       _testResults = 'Testowanie połączenia...\n\n';
//     });
//
//     List<String> results = [];
//
//     Test 1: Podstawowe połączenie
// try {
//   results.add('=== TEST 1: Ping serwera ===');
//   final response = await http
//       .get(Uri.parse(fuckingUrl), headers: {'Connection': 'close'})
//       .timeout(Duration(seconds: 10));
//   results.add('✅ Serwer odpowiada: ${response.statusCode}');
//   results.add('Headers: ${response.headers}');
// } catch (e) {
//   results.add('❌ Błąd połączenia: $e');
// }
//
// results.add('\n=== TEST 2: HEAD request na video.dart ===');
// try {
//   final response = await http
//       .head(Uri.parse(fuckingUrl), headers: {'Connection': 'close'})
//       .timeout(Duration(seconds: 10));
//   results.add('✅ Status: ${response.statusCode}');
//   results.add(
//     'Content-Type: ${response.headers['content-type'] ?? 'brak'}',
//   );
//   results.add(
//     'Content-Length: ${response.headers['content-length'] ?? 'brak'}',
//   );
//   results.add(
//     'Accept-Ranges: ${response.headers['accept-ranges'] ?? 'brak'}',
//   );
// } catch (e) {
//   results.add('❌ Błąd HEAD request: $e');
// }
//
// results.add('\n=== TEST 3: Range request ===');
// try {
//   final response = await http
//       .get(
//         Uri.parse(fuckingUrl),
//         headers: {'Range': 'bytes=0-1023', 'Connection': 'close'},
//       )
//       .timeout(Duration(seconds: 10));
//   results.add('✅ Range request: ${response.statusCode}');
//   results.add(
//     'Content-Range: ${response.headers['content-range'] ?? 'brak'}',
//   );
//   results.add('Otrzymane bajty: ${response.bodyBytes.length}');
// } catch (e) {
//   results.add('❌ Błąd range request: $e');
// }
//
// results.add('\n=== TEST 4: Pełne pobranie (pierwsze 2KB) ===');
// try {
//   final response = await http
//       .get(
//         Uri.parse('http://192.168.0.22:8000/BigBuckBunny.mp4'),
//         headers: {'Connection': 'close'},
//       )
//       .timeout(Duration(seconds: 15));
//
//   if (response.statusCode == 200) {
//     results.add('✅ Status: ${response.statusCode}');
//     results.add('Rozmiar odpowiedzi: ${response.bodyBytes.length} bajtów');
//
//     Sprawdź czy to rzeczywiście video.dart
// final bytes = response.bodyBytes;
// if (bytes.length >= 4) {
//   final header = bytes.sublist(0, 4);
//   if (header[0] == 0x00 && header[1] == 0x00 && header[2] == 0x00) {
//     results.add('✅ Wygląda na plik MP4 (poprawny header)');
//   } else {
//     results.add(
//       '⚠️ Niepoprawny header MP4: ${header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
//     );
//   }
// }
// } else {
//   results.add('❌ Status: ${response.statusCode}');
// }
// } catch (e) {
//   results.add('❌ Błąd pełnego pobrania: $e');
// }
//
// setState(() {
//   _testResults = results.join('\n');
//   _isLoading = false;
// });
// }
//
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: Colors.black,
//     body: Padding(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         children: [
//           ElevatedButton(
//             onPressed: _isLoading ? null : runNetworkTests,
//             child:
//                 _isLoading
//                     ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         SizedBox(
//                           width: 16,
//                           height: 16,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         ),
//                         SizedBox(width: 8),
//                         Text('Testowanie...'),
//                       ],
//                     )
//                     : Text('Uruchom testy połączenia'),
//           ),
//           SizedBox(height: 16),
//           Expanded(
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[900],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: SingleChildScrollView(
//                 child: Text(
//                   _testResults.isEmpty
//                       ? 'Kliknij przycisk aby uruchomić testy'
//                       : _testResults,
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontFamily: 'monospace',
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
// }
