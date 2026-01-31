import 'package:flutter/material.dart';

class ScanErrorCard extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onOpenAppSettings;

  const ScanErrorCard({
    super.key,
    required this.errorMessage,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onOpenLocationSettings,
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('Lokalizacja'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpenAppSettings,
                  icon: const Icon(Icons.app_settings_alt, size: 18),
                  label: const Text('Uprawnienia'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}