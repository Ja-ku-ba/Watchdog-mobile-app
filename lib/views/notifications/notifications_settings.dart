import 'package:flutter/material.dart';
import 'package:watchdog/layouts/base/loged_in_layout.dart';
import 'package:watchdog/utils/request.dart';
import 'package:watchdog/models/notification_settings_model.dart';


class NotificationsSettings extends StatefulWidget {
  const NotificationsSettings({super.key});

  @override
  NotificationsSettingsState createState() => NotificationsSettingsState();
}

class NotificationsSettingsState extends State<NotificationsSettings> {
  NotificationSettingsModel? _settings;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final client = RequestClient();
      await client.initialize();

      final response = await client.get('/users/user-notification-settings');
      setState(() {
        _settings = NotificationSettingsModel.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Nie udało się pobrać ustawień';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings() async {
    if (_settings == null) return;
    try {
      final client = RequestClient();
      await client.initialize();
      await client.put('/users/user-notification-update', data: _settings!.toJson());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zapisać ustawień')),
      );
      _fetchSettings();
    }
  }

  Future<bool> _showConfirmDialog(String title, String message, bool newValue) async {
    final action = newValue ? 'włączyć' : 'wyłączyć';
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Czy na pewno chcesz $action $message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Potwierdź'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSwitchChanged(
      String key,
      String title,
      String description,
      bool currentValue,
      ) async {
    final newValue = !currentValue;
    final confirmed = await _showConfirmDialog(title, description, newValue);

    if (confirmed) {
      setState(() {
        switch (key) {
          case 'new_video':
            _settings!.notificationNewVideo = newValue;
            break;
          case 'intruder':
            _settings!.notificationIntruder = newValue;
            break;
          case 'friend':
            _settings!.notificationFriend = newValue;
            break;
        }
      });
      await _updateSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSettings,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNotificationTile(
          key: 'new_video',
          title: 'Nowe nagrania',
          description: 'powiadomienia o nowych nagraniach',
          icon: Icons.videocam,
          value: _settings!.notificationNewVideo,
        ),
        _buildNotificationTile(
          key: 'intruder',
          title: 'Wykrycie intruza',
          description: 'powiadomienia o wykryciu intruza',
          icon: Icons.warning,
          value: _settings!.notificationIntruder,
        ),
        _buildNotificationTile(
          key: 'friend',
          title: 'Domownicy',
          description: 'powiadomienia o wykryciu domownika',
          icon: Icons.people,
          value: _settings!.notificationFriend,
        ),
      ],
    );
  }

  Widget _buildNotificationTile({
    required String key,
    required String title,
    required String description,
    required IconData icon,
    required bool value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: Switch(
          activeColor: Colors.blue,
          inactiveTrackColor: Colors.grey[300],
          inactiveThumbColor: Colors.grey[600],
          value: value,
          onChanged: (_) => _onSwitchChanged(key, title, description, value),
        ),
      ),
    );
  }
}
