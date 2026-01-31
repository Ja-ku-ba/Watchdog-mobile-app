import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watchdog/layouts/base/loged_in_layout.dart';
import 'package:watchdog/utils/request.dart';
import 'package:watchdog/models/video.dart';
import 'package:watchdog/components/loading.dart';

import '../../models/devices_with_ips.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _videosController = ScrollController();
  List<Video> videos = [];
  List<DeviceWithIp> devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _videosController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    final client = RequestClient();
    await client.initialize();

    try {
      final response = await client.get('/videos/get-videos');
      devices.addAll(
        (response.data['configured_devices'] as List)
            .map((json) => DeviceWithIp.fromJson(json))
            .toList(),
      );
      videos.addAll(
        (response.data['videos'] as List)
            .map((json) => Video.fromJson(json))
            .toList(),
      );
    } catch (e) {
      print("Loading error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
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
            if (devices.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  itemCount: devices.length == 1 ? 1 : 100000,
                  itemBuilder: (context, index) {
                    final device = devices[index % devices.length];
                    return Container(
                      width: devices.length == 1
                          ? MediaQuery.of(context).size.width - 30
                          : MediaQuery.of(context).size.width - 40,
                      child: Card(
                        elevation: 0,
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
                                  url: 'rtsp://${device.device_ip}:8554/camera',
                                ),
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.videocam, size: 32, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.device_name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Podgląd na żywo',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    "Brak skonfigurowanych urządzeń",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],

            Divider(height: 0, thickness: 1, color: Colors.grey),

            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: LoadingCircle(size: 40)),
              ),
            if (!_isLoading && videos.isEmpty) Text('Brak nagrań'),

            if (!_isLoading && videos.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  controller: _videosController,
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    return Column(
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
                          title: Text(
                            '${formatDate(videos[index].recordedAt!)}',
                          ),
                          subtitle: Text(
                            '${videos[index].camera}',
                          ),
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed(
                              '/video',
                              arguments: {'video': videos[index]},
                            );
                          },
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey),
                      ],
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