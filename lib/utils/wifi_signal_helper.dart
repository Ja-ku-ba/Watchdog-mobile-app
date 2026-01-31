import 'package:flutter/material.dart';

class WiFiSignalHelper {
  static Color getSignalColor(int level) {
    if (level >= -50) return Colors.green;
    if (level >= -60) return Colors.lightGreen;
    if (level >= -70) return Colors.orange;
    if (level >= -80) return Colors.deepOrange;
    return Colors.red;
  }

  static int getSignalBars(int level) {
    if (level >= -50) return 4;
    if (level >= -60) return 3;
    if (level >= -70) return 2;
    if (level >= -80) return 1;
    return 0;
  }

  static Widget buildSignalIcon(int level) {
    final bars = getSignalBars(level);
    final color = getSignalColor(level);

    IconData icon;
    switch (bars) {
      case 4:
        icon = Icons.network_wifi;
        break;
      case 3:
        icon = Icons.network_wifi_3_bar;
        break;
      case 2:
        icon = Icons.network_wifi_2_bar;
        break;
      case 1:
        icon = Icons.network_wifi_1_bar;
        break;
      default:
        icon = Icons.signal_wifi_0_bar;
    }

    return Icon(icon, color: color);
  }
}