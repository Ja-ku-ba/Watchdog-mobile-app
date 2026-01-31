import 'package:flutter/material.dart';

class CurrentConnectionCard extends StatelessWidget {
  final bool isLoading;
  final String? currentSSID;
  final bool isXyzNetwork;

  const CurrentConnectionCard({
    super.key,
    required this.isLoading,
    required this.currentSSID,
    required this.isXyzNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Twoje połączenie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (currentSSID != null)
              Row(
                children: [
                  Icon(
                    Icons.wifi,
                    color: isXyzNetwork ? Colors.green : Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSSID!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isXyzNetwork)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '✓ Sieć XYZ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            else
              const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Brak połączenia',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
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