import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:watchdog/components/double_back_bo_exit.dart';
import 'package:watchdog/views/auth/login.dart';
import 'package:watchdog/views/auth/register.dart';
import 'package:watchdog/views/base/home.dart';
import 'package:watchdog/views/tests.dart';
import 'package:watchdog/views/videos/fullscreen_video.dart';
import 'package:watchdog/views/videos/video.dart';
import 'services/auth.dart';

void main() => runApp(MyApp());
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // WidgetsFlutterBinding.ensureInitialized();
    return MaterialApp(
      title: 'Watchdog, Twój system monitorowania',
      // theme: ThemeData(primarySwatch: Colors.blue),
      theme: ThemeData(
        primaryColor: const Color(0xFFFFECD1),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF1B1B1B),
        ),
      ),

      home: DoubleBackToExit(child: AuthGate()),
      navigatorKey: navigatorKey,
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/video': (context) => VideoPage(),
        '/video/full-mode': (context) => FullscreenVideoPage(),
        '/tests': (context) => TestPage(),
      },
    );
  }
}


class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    AuthService.isLoggedIn().then((logged) {
      setState(() {
        _loggedIn = logged;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    // return Scaffold(body: Center(child: CircularProgressIndicator()));
    return _loggedIn ? HomePage() : LoginPage();
  }
}
