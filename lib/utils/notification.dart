import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth.dart';

class TokenManager {
  static Future<String?> ensureToken() async {
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

  static Future<void> linkTokenToUser(String userId) async {
    String? token = await ensureToken();

    if (token == null) {
      return;
    }

    try {
      await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/link-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}',
        },
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('API error: $e');
    }
  }
}