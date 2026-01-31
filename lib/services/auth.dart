import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:watchdog/main.dart';

import '../utils/request.dart';

class AuthService {
  static const int accessTokenLifespanInMinutes = 60;

  static String? _baseUrl;

  static String get baseUrl {
    _baseUrl ??= dotenv.env['BASE_URL'];
    return _baseUrl!;
  }

  static Future<String?> ensureFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('fcm_token');

    if (token == null) {
      token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await prefs.setString('fcm_token', token);
      }
    }

    return token;
  }

  static Future<bool> linkFcmToken() async {
    try {
      String? fcmToken = await ensureFcmToken();

      if (fcmToken == null) {
        return false;
      }

      String? accessToken = await getToken();
      if (accessToken == null) {
        return false;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/users/notification-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'notification_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> unlinkFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? fcmToken = prefs.getString('fcm_token');

      if (fcmToken == null) return true;

      String? accessToken = await getToken();
      if (accessToken == null) return true;

      final response = await http.delete(
        Uri.parse('$baseUrl/users/notification-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<({bool success, String? error})> register(String email, String password, String username) async {
    try {
      final client = RequestClient();
      await client.initialize();
      final response = await client.post(
          '/users/register',
          data: {
            'email': email,
            'password': password,
            'username': username
          }
      );

      final data = response.data;
      if (response.statusCode == 200) {
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);

        await linkFcmToken();

        return (success: true, error: null);
      } else if (data["detail"] != null && data["detail"].isNotEmpty) {
        return (
          success: false,
          error: data['detail'] as String
        );
      }
    } catch (e) {
      print("Register error $e");
    }
    return (success: false, error: null);
  }

  static Future<({bool success, String? error})> login(String email, String password) async {
    try {
      final client = RequestClient();
      await client.initialize();
      final response = await client.post(
          '/users/login',
          data: {
            'email': email,
            'password': password,
          }
      );


      final data = response.data;
      if (response.statusCode == 200) {
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('user_email', email);

        tokenRefresher();
        await linkFcmToken();

        return (success: true, error: null);
      } else if (data["detail"] != null && data["detail"].isNotEmpty) {
        return (
          success: false,
          error: data['detail'] as String
        );
      }
    } catch (e) {
      print("Login error $e");
    }
    return (success: false, error: null);
  }

  static Future<void> logout() async {
    await unlinkFcmToken();
    await removeTokens();
  }

  static Future<bool> isLoggedIn() async {
    final isTokenValid = await validateToken();
    return isTokenValid;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<bool> refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');
      String? accessToken = prefs.getString('access_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        await removeTokens();
        return false;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/users/new-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final accessToken = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.setString('access_token', accessToken);
        return true;
      }
    } catch (e) {
      print("Fmc token refreshing error $e");
    }
    return false;
  }

  static Future<bool> validateToken({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = "";
    if (!refresh) {
      token = prefs.getString('access_token');
    } else {
      token = prefs.getString('refresh_token');
    }

    if (token == null || token.isEmpty) {
      await removeTokens();
      return false;
    }
    DateTime expirationDate = JwtDecoder.getExpirationDate(token);
    final timeLeft = expirationDate.difference(DateTime.now());

    if (timeLeft.inMinutes <= 10 && timeLeft.inMinutes > 0) {
      bool isTokenRefreshed = await AuthService.refresh();
      if (isTokenRefreshed) {
        return validateToken(refresh: refresh);
      } else {
        return false;
      }
    } else if (timeLeft.isNegative) {
      await removeTokens();
      return false;
    }
    return !JwtDecoder.isExpired(token);
  }

  static Future<void> removeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_email');
  }

  static Future<void> tokenRefresher() async {
    Timer.periodic(
      Duration(minutes: accessTokenLifespanInMinutes - 5),
      (timer) async {
        bool isRefreshed = await refresh();
        if (!isRefreshed) {
          timer.cancel();
          logout();
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login',
                (route) => false,
          );
        }
      }
    );
  }
}
