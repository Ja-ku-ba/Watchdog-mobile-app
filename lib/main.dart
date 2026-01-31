import 'package:watchdog/views/verified_users/add_user.dart';
import 'package:watchdog/views/verified_users/edit_user.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';

import 'package:watchdog/components/double_back_bo_exit.dart';
import 'package:watchdog/views/auth/login.dart';
import 'package:watchdog/views/auth/register.dart';
import 'package:watchdog/views/base/home.dart';
import 'package:watchdog/views/videos/video.dart';
import 'package:watchdog/views/devices/devices.dart';
import 'package:watchdog/views/devices/add_device.dart';
import 'package:watchdog/views/devices/exteranl_device_password.dart';
import 'package:watchdog/views/notifications/notifications_settings.dart';
import 'package:watchdog/views/verified_users/users_list.dart';

import 'package:watchdog/services/auth.dart';
import 'package:watchdog/services/notification.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }
  runApp(MyApp());
}


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize(navigatorKey);
      await AuthService.ensureFcmToken();
      // String? token = await AuthService.ensureFcmToken();
    } catch (e) {
      print("Erroe while notifications init: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      title: 'Watchdog',
      debugShowCheckedModeBanner: false,
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
        '/devices': (context) => DevicesList(),
        '/add_device': (context) => WiFiNetworksScreen(),
        '/notifications': (context) => NotificationsSettings(),
        '/video': (context) => VideoPage(),
        '/verified_users': (context) => VerifiedUsersList(),
        '/add_user': (context) => AddVerifiedUser(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/external_device_password') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ExteranlDevicePassword(
              network_ssid: args['network_ssid'],
            ),
          );
        } else if (settings.name == '/edit_verified_user') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EditVerifiedUser(
              verifiedUser: args['verified_user'],
            ),
          );
        }
        return null;
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
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _loggedIn ? HomePage() : LoginPage();
  }
}
