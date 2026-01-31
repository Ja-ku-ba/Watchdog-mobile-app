import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';

import 'package:watchdog/utils/wifi_signal_helper.dart';


class NetworkListItem extends StatelessWidget {
  final WiFiAccessPoint network;
  final bool isCurrentNetwork;

  const NetworkListItem({
    super.key,
    required this.network,
    required this.isCurrentNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isCurrentNetwork ? Colors.blue[50] : null,
      elevation: isCurrentNetwork ? 4 : 1,
      child: ListTile(
        leading: WiFiSignalHelper.buildSignalIcon(network.level),
        title: Text(
          network.ssid.isEmpty ? '<Ukryta sieć>' : network.ssid,
          style: TextStyle(
            fontWeight: isCurrentNetwork
                ? FontWeight.bold
                : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: isCurrentNetwork
            ? Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Połączona',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
            : null,
      ),
    );
  }
}