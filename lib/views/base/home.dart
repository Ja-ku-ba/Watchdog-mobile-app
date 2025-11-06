import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watchdog/layouts/base/loged_in_layout.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
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
      print(videos);
    } catch (e) {
      print("Błąd podczas ładowania: $e");
    } finally {
      setState(() => _isLoading = false);
    }

    setState(() {
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

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed(
                      '/video',
                      arguments: {
                        'video': Video(
                          url: 'rtsp://10.244.60.99:8554/camera',
                        ),
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Live',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Podgląd na żywo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Divider(height: 0, thickness: 1, color: Colors.grey,),
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
                              child: Icon(
                                Icons.slow_motion_video,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          title: Text('${videos[index].recordedAt != null ? formatDate(videos[index].recordedAt!) : ''} ${videos[index].camera}'),
                          subtitle: Text(
                            '${videos[index].type}, długość nagrania: ',
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
