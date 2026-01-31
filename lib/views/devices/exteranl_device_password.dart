import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:watchdog/components/snackBars.dart';

class ExteranlDevicePassword extends StatefulWidget {
  final String network_ssid;

  const ExteranlDevicePassword({Key? key, required this.network_ssid})
    : super(key: key);

  @override
  State<ExteranlDevicePassword> createState() => _ExteranlDevicePasswordState();
}

class _ExteranlDevicePasswordState extends State<ExteranlDevicePassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  static String? _deviceBaseUrl;

  static String get deviceBaseUrl {
    _deviceBaseUrl ??= dotenv.env['DEVICE_AP_URL'];
    return _deviceBaseUrl!;
  }

  Future<void> _sendPostRequest(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    final password = _passwordController.text.trim();
    final deviceName = _deviceNameController.text.trim();
    bool success = false;
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('user_email');
      await http.post(
        Uri.parse('$deviceBaseUrl/api/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_name': deviceName,
          'password': password,
          'email': userEmail,
          'ssid': widget.network_ssid,
        }),
      ).timeout(
        const Duration(seconds: 15),
      );
    } catch (e) {
      print('Błąd requesta: $e');
      // success = true, if raspberry c onect itself to exteranal network
      // then connection will be broken via AP
      success = true;
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      showSnackBar(
        context,
        'Możesz się połączyć z normalną siecią i sprawdzić status synchronizacji',
        color: Colors.blue,
      );
    } else {
      showSnackBar(
        context,
        'Wystąpił błąd synchronizacji, spróbuj ponownie',
        color: Colors.blue,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(widget.network_ssid), elevation: 2),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Hasło wymagane do poąłczenia z wybraną siecią',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nazwa urządzenia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: _deviceNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 1,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nazwa urządzenia jest wymagana';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _sendPostRequest(context);
                          },
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cable),
                    label: Text(_isLoading ? 'Łączenie...' : 'Połącz'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
