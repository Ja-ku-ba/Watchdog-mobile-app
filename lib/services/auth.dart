import 'dart:async';
import 'package:watchdog/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  static const int accessTokenLifespanInMinutes = 60;
  static const String baseUrl = "http://192.168.0.22:8000";

  static Future<({bool success, String? error})> register(String email, String password, String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'username': username}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        return (success: true, error: null);
      } else if (data["detail"] != null && data["detail"].isNotEmpty) {
        return (success: false, error: data['detail'] as String ?? 'Coś poszło nie tak, pracujemy nad tym');
      }
    } catch (e) {
      print(';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
      print(e);
      print(';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
    }
    return (success: false, error: null);
  }

  static Future<({bool success, String? error})> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        AuthService.tokenRefresher();
        return (success: true, error: null);
      } else if (data["detail"]) {
        return (success: false, error: data['detail'] as String ?? 'Coś poszło nie tak, pracujemy nad tym');
      }
    } catch (e) {
      print(';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
      print(e);
      print(';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
    }
    return (success: false, error: null);
  }

  static Future<void> logout() async {
    await AuthService.removeTokens();
  }

  static Future<bool> isLoggedIn() async {
    // final prefs = await SharedPreferences.getInstance();
    final isTokenValid = await AuthService.validateToken();
    return isTokenValid;
    // return prefs.containsKey('access_token');
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
        await AuthService.removeTokens();
        return false;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/users/new-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'refresh_token': refreshToken!}),
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
      print(e);
    }
    return false;
  }

  static Future<bool> validateToken ({ bool refresh = false }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = "";
    if (!refresh) {
      token = prefs.getString('access_token');
    } else {
      token = prefs.getString('refresh_token');
    }

    if (token == null || token.isEmpty) {
      // throw Exception("Brak tokenu");
      await AuthService.removeTokens();
      return false;
    }
    DateTime expirationDate = JwtDecoder.getExpirationDate(token);
    final timeLeft = expirationDate.difference(DateTime.now());

    if (timeLeft.inMinutes <= 10 && timeLeft.inMinutes > 0) {
      bool isTokeRefreshed = await AuthService.refresh();
      if (isTokeRefreshed) {
        return validateToken(refresh: refresh);
      } else {
        return false;
      }
    } else if (timeLeft.isNegative) {
      // throw Exception('Brak ważnego tokenu');
      await AuthService.removeTokens();
      return false;
    }
    return !JwtDecoder.isExpired(token);
  }

  static Future<void> removeTokens () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<void> tokenRefresher () async {
    Timer.periodic(Duration(minutes: accessTokenLifespanInMinutes - 5), (timer) async {
    // Timer.periodic(Duration(seconds: 30), (timer) async {
      bool isRefreshed = await AuthService.refresh();
      print("Refreshed ${isRefreshed}");
      if (!isRefreshed) {
        timer.cancel();
        AuthService.logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );      }
    });
  }
}
