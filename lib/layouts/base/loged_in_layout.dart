import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watchdog/services/auth.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerManager {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();

  factory VideoPlayerManager() => _instance;

  VideoPlayerManager._internal();

  final List<VideoPlayerController> _activeControllers = [];

  void registerController(VideoPlayerController controller) {
    _activeControllers.add(controller);
  }

  void unregisterController(VideoPlayerController controller) {
    _activeControllers.remove(controller);
  }

  void pauseAllControllers() {
    for (final controller in _activeControllers) {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void disposeAllControllers() {
    for (final controller in _activeControllers) {
      controller.dispose();
    }
    _activeControllers.clear();
  }
}

class AppLayout extends StatefulWidget {
  final Widget child;

  const AppLayout({required this.child, super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();

  static Future<void> logoutUser(context) async {
    VideoPlayerManager().pauseAllControllers();
    AuthService.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  //    ToDO: Zwraca błędy z contextem, napraw to albo zaplikuj globalnego mesengera
  //   static void showMesenger(BuildContext context) {
  //     VideoPlayerManager().pauseAllControllers();
  //
  //     Navigator.of(context).pop();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         backgroundColor: Colors.red,
  //         content: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(child: Text('Funkcja jeszcze nie gotowa, aplikacja w tym momencie skupia się na streamingu')),
  //             IconButton(
  //                 onPressed: () {
  //                   ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //                 },
  //                 icon: Icon(
  //                   Icons.close,
  //                   color: Colors.white,
  //                 )
  //             )
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }
  static void showMesenger(BuildContext context) {
    VideoPlayerManager().pauseAllControllers();

    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Funkcja niedostępna'),
            content: Text(
              'Funkcja jeszcze nie gotowa, aplikacja skupia się na streamingu',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }
}

class _AppLayoutState extends State<AppLayout> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        VideoPlayerManager().pauseAllControllers();
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.hidden:
        VideoPlayerManager().pauseAllControllers();
        break;
    }
  }

  void _pauseVideoBeforeNavigation() {
    VideoPlayerManager().pauseAllControllers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: () {
            _pauseVideoBeforeNavigation();
            Navigator.of(context).pushNamed('/home');
          },
          child: Text(
            'Watchdog',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w300),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            shadowColor: Colors.transparent,
          ),
        ),
      ),
      body: Padding(padding: const EdgeInsets.all(16.0), child: widget.child),
      drawer: Drawer(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        DrawerHeader(
                          child: Text(
                            "Watchdog, Twój system monitorowania",
                            style: TextStyle(
                              fontSize: 25,
                              shadows: [
                                Shadow(
                                  offset: Offset(10, 10),
                                  blurRadius: 0,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text("Strona główna"),
                          onTap: () {
                            _pauseVideoBeforeNavigation();
                            Navigator.pushNamed(context, '/home');
                          },
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey),
                        ListTile(
                          title: Text("Profil"),
                          onTap: () => AppLayout.showMesenger(context),
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey),
                        ListTile(
                          title: Text("Ustawienia"),
                          onTap: () => AppLayout.showMesenger(context),
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey),
                        ListTile(
                          title: Text("Urządzenia"),
                          onTap: () => AppLayout.showMesenger(context),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text("Wyloguj"),
                      onTap: () => AppLayout.logoutUser(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
