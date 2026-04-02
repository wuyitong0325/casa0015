import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ble/ble_iaq_client.dart';

class ScanConnectPage extends StatefulWidget {
  final BleIaqClient ble;
  final bool demoMode;
  final VoidCallback onStartDemoMode;
  final VoidCallback onStopDemoMode;

  const ScanConnectPage({
    super.key,
    required this.ble,
    required this.demoMode,
    required this.onStartDemoMode,
    required this.onStopDemoMode,
  });

  @override
  State<ScanConnectPage> createState() => _ScanConnectPageState();
}

class _ScanConnectPageState extends State<ScanConnectPage> {
  bool scanning = false;
  String status = "Not connected";
  List<ScanResult> results = [];

  @override
  void initState() {
    super.initState();
    widget.ble.connected.listen((c) {
      if (!mounted) return;
      if (!widget.demoMode) {
        setState(() => status = c ? "Connected" : "Not connected");
      }
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  Future<void> _scan() async {
    setState(() {
      scanning = true;
      status = "Scanning...";
      results = [];
    });

    try {
      await _requestPermissions();

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        if (!mounted) return;
        setState(() {
          status = "Bluetooth is OFF";
          scanning = false;
        });
        return;
      }

      final Map<DeviceIdentifier, ScanResult> found = {};

      final sub = FlutterBluePlus.scanResults.listen((list) {
        for (final r in list) {
          found[r.device.remoteId] = r;
        }
        if (!mounted) return;
        setState(() {
          results = found.values.toList()
            ..sort((a, b) => b.rssi.compareTo(a.rssi));
        });
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
      await Future.delayed(const Duration(seconds: 6));
      await FlutterBluePlus.stopScan();
      await sub.cancel();

      if (!mounted) return;
      setState(() {
        status = results.isEmpty
            ? "No devices found"
            : "Scan done. Tap a device to connect.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => status = "Scan error: $e");
    } finally {
      if (!mounted) {
        return;
      }
      setState(() => scanning = false);
    }
  }

  Future<void> _connect(ScanResult r) async {
    setState(() => status = "Connecting to ${_deviceName(r)}...");
    try {
      await widget.ble.connect(r.device);
      if (!mounted) return;
      setState(() => status = "Connected to ${_deviceName(r)}");
    } catch (e) {
      if (!mounted) return;
      setState(() => status = "Connect error: $e");
    }
  }

  String _deviceName(ScanResult r) {
    final name = r.device.platformName.trim();
    if (name.isNotEmpty) return name;

    final advName = r.advertisementData.advName.trim();
    if (advName.isNotEmpty) return advName;

    return "(no name)";
  }

  @override
  Widget build(BuildContext context) {
    final modeText = widget.demoMode ? "Demo Mode Active" : "Live BLE Mode";

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Mode: $modeText",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "BLE Status: $status",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: scanning ? null : _scan,
              icon: const Icon(Icons.search),
              label: Text(scanning ? "Scanning..." : "Scan BLE Device"),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.demoMode ? null : widget.onStartDemoMode,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Demo Mode"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.demoMode ? widget.onStopDemoMode : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text("Stop Demo Mode"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text("No scan results yet"))
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = results[i];
                        final name = _deviceName(r);
                        return ListTile(
                          title: Text(name),
                          subtitle: Text(
                            "${r.device.remoteId.str}  |  RSSI ${r.rssi}",
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _connect(r),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => widget.ble.disconnect(),
              icon: const Icon(Icons.link_off),
              label: const Text("Disconnect BLE"),
            ),
          ],
        ),
      ),
    );
  }
}