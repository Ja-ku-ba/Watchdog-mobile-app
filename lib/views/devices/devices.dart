import 'package:flutter/material.dart';
import 'package:watchdog/layouts/base/loged_in_layout.dart';
import 'package:watchdog/utils/request.dart';
import 'package:watchdog/models/devices.dart';


class DevicesList extends StatefulWidget {
  const DevicesList({super.key});

  @override
  DevicesListState createState() => DevicesListState();
}

class DevicesListState extends State<DevicesList> {
  List<Device>? _devices;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    try {
      final client = RequestClient();
      await client.initialize();

      final response = await client.get('/users/user-groups-list');
      setState(() {
        _devices = (response.data as List).map((e) => Device.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("$e");
      setState(() {
        _error = 'Nie udało się pobrać urządzeń';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: SafeArea(
        child: Scaffold(
          body: _buildContent(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).pushNamed('/add_device'),
            icon: Icon(Icons.add_a_photo_outlined),
            label: Text('Dodaj urządzenie'),
          ),
        ),
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
              onPressed: _fetchDevices,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
        _devices?.map(
          (device) => _buildDeviceTile(
              device: device,
            ),
      ).toList() ?? [],
    );
  }

  Widget _buildDeviceTile({
    required Device device,
  }) {
    return Card(
      child: ExpansionTile(
        title: Text(device.name),
        subtitle: Text("Użytkowników: ${device.users?.length ?? 0}"),
        leading: Icon(Icons.camera_outdoor),
        children:
          device.users?.map(
              (user) => ListTile(
            title: Text('$user'),
          ),
        ).toList() ?? [],
      ),
    );
  }
}
