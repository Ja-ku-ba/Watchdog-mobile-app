import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

import '../../components/dialogs/network_list_item.dart';
import '../../components/dialogs/permission_dialog.dart';
import '../../components/dialogs/scan_error_card.dart';
import '../../components/dialogs/xyz_connection_dialog.dart';
import '../../layouts/base/loged_in_layout.dart';


class WiFiNetworksScreen extends StatefulWidget {
  const WiFiNetworksScreen({Key? key}) : super(key: key);

  @override
  State<WiFiNetworksScreen> createState() => _WiFiNetworksScreenState();
}

class _WiFiNetworksScreenState extends State<WiFiNetworksScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();

  String? _currentSSID;

  List<WiFiAccessPoint> _availableNetworks = [];
  bool _isScanning = false;
  String? _scanError;
  final String? _deviceBaseName = dotenv.env['DEVICE_AP_NAME'];

  @override
  void initState() {
    super.initState();
    _loadCurrentNetwork();
  }

  bool _isXyzNetwork() {
    if (_deviceBaseName == null || _deviceBaseName.isEmpty) {
      return false;
    }
    return _currentSSID != null && _currentSSID!.toLowerCase() == _deviceBaseName.toLowerCase();
  }

  Future<void> _requestPermissions() async {
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      if (mounted) {
        PermissionDialog.show(
          context,
          onOpenSettings: _openAppSettings,
        );
      }
    }
  }

  Future<void> _openLocationSettings() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.LOCATION_SOURCE_SETTINGS',
      );
      await intent.launch();
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  Future<void> _loadCurrentNetwork() async {
    // setState(() {
    //   _isLoadingCurrent = true;
    // });

    try {
      final ssid = await _networkInfo.getWifiName();

      setState(() {
        _currentSSID = ssid?.replaceAll('"', '');
        // _isLoadingCurrent = false;
      });
    } catch (e) {
      setState(() {
        _currentSSID = null;
        // _isLoadingCurrent = false;
      });
    }
  }

  Future<void> _scanNetworks() async {
    setState(() {
      _isScanning = true;
      _scanError = null;
    });

    await _loadCurrentNetwork();

    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      await _requestPermissions();
      setState(() {
        _isScanning = false;
      });
      return;
    }

    try {
      final canScan = await WiFiScan.instance.canStartScan();

      if (canScan == CanStartScan.yes) {
        final result = await WiFiScan.instance.startScan();

        if (result) {
          await Future.delayed(const Duration(seconds: 2));

          final networks = await WiFiScan.instance.getScannedResults();

          final filteredNetworks = networks
              .where((network) => network.ssid.isNotEmpty)
              .toList();
          filteredNetworks.sort((a, b) => b.level.compareTo(a.level));

          final uniqueNetworks = <String, WiFiAccessPoint>{};
          for (var network in filteredNetworks) {
            if (!uniqueNetworks.containsKey(network.ssid)) {
              uniqueNetworks[network.ssid] = network;
            }
          }

          setState(() {
            _availableNetworks = uniqueNetworks.values.toList();
            _isScanning = false;
            _scanError = null;
          });

          if (_isXyzNetwork()) {
            XyzConnectionDialog.show(
              context,
              currentSSID: _currentSSID,
              availableNetworks: _availableNetworks,
              onNetworkSelected: (ssid) {
                Navigator.pushNamed(
                  context,
                  '/external_device_password',
                  arguments: {
                    'network_ssid': ssid,
                  },
                );
              },
            );
          }
        } else {
          setState(() {
            _scanError = 'Nie udało się rozpocząć skanowania';
            _isScanning = false;
          });
        }
      } else {
        _handleScanError(canScan);
      }
    } catch (e) {
      setState(() {
        _scanError = 'Błąd: $e';
        _isScanning = false;
      });
    }
  }

  void _handleScanError(CanStartScan canScan) {
    String errorMessage;

    switch (canScan) {
      case CanStartScan.noLocationServiceDisabled:
        errorMessage = 'Lokalizacja jest wyłączona w ustawieniach systemowych';
        break;
      case CanStartScan.noLocationPermissionDenied:
        errorMessage = 'Brak uprawnień do lokalizacji';
        break;
      case CanStartScan.noLocationPermissionRequired:
        errorMessage = 'Wymagane uprawnienia do lokalizacji';
        break;
      case CanStartScan.failed:
        errorMessage = 'Skanowanie nie powiodło się';
        break;
      default:
        errorMessage = 'Skanowanie niedostępne: $canScan';
    }

    setState(() {
      _scanError = errorMessage;
      _isScanning = false;
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informacja'),
        content: const Text(
          'Jak korzystać z aplikacji:\n\n'
              '1. Połącz się z siecią Wi-Fi\n'
              '2. Włącz lokalizację w telefonie\n'
              '3. Przyznaj uprawnienia do lokalizacji\n'
              '4. Naciśnij przycisk "Skanuj"\n\n'
              'Jeśli jesteś połączony z siecią zaczynającą się od "xyz", '
              'zobaczysz specjalne powiadomienie!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sieci Wi-Fi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: _showHelpDialog,
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadCurrentNetwork();
                  await _scanNetworks();
                },
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dostępne sieci (${_availableNetworks.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isScanning ? null : _scanNetworks,
                          icon: _isScanning
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.search),
                          label: Text(_isScanning ? 'Skanowanie...' : 'Skanuj'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_scanError != null)
                      ScanErrorCard(
                        errorMessage: _scanError!,
                        onOpenLocationSettings: _openLocationSettings,
                        onOpenAppSettings: _openAppSettings,
                      )
                    else if (_availableNetworks.isEmpty && !_isScanning)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.wifi_find, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text(
                                'Naciśnij "Skanuj" aby wyszukać sieci w pobliżu',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._availableNetworks.map((network) {
                        return NetworkListItem(
                          network: network,
                          isCurrentNetwork: network.ssid == _currentSSID,
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
