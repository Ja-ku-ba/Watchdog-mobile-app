import 'package:flutter/material.dart';

class PermissionDialog {
  static Future<void> show(
      BuildContext context, {
        required VoidCallback onOpenSettings,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Brak uprawnień'),
            ],
          ),
          content: const Text(
            'Aplikacja potrzebuje dostępu do lokalizacji, aby móc skanować sieci Wi-Fi.\n\n'
                'Przyznaj uprawnienia w ustawieniach aplikacji.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Ustawienia aplikacji'),
            ),
          ],
        );
      },
    );
  }
}