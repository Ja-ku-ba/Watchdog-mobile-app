import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:watchdog/services/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


const String baseUrl = 'http://192.168.0.22:8000/';

class RequestClient {
  late Dio _dio;
  String? _token;

  RequestClient() {
    _dio = Dio();
    _setupInterceptors();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            AuthService.refresh();
          }
          handler.next(error);
        },
      ),
    );
  }

  void setToken(String token) {
    _token = token;
  }


  Future<Response> get(String path) async {
    return await _dio.get('$baseUrl$path');
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post('$baseUrl$path', data: data);
  }

  Future<Uint8List> getImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await _dio.get(
        '$baseUrl$path',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      return Uint8List.fromList(response.data);
    } catch(e) {
      final response = await _dio.get(
        '$baseUrl$path',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      return Uint8List.fromList(response.data);
    }
  }
}
