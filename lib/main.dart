import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'ble/ble_iaq_client.dart';
import 'models/iaq_sample.dart';
import 'models/thresholds.dart';
import 'storage/thresholds_store.dart';
import 'pages/scan_connect_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/history_page.dart';
import 'pages/settings_page.dart';
import 'services/demo_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const IaqApp());
}

class IaqApp extends StatelessWidget {
  const IaqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IAQ Gauge',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final BleIaqClient ble = BleIaqClient();
  final DemoDataService demo = DemoDataService();
  final ThresholdsStore store = ThresholdsStore();

  Thresholds thresholds = Thresholds.defaults();
  bool thresholdsLoaded = false;

  int tab = 0;
  bool demoMode = false;

  Stream<IaqSample> get activeSampleStream =>
      demoMode ? demo.samples : ble.samples;

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    final t = await store.load();
    setState(() {
      thresholds = t;
      thresholdsLoaded = true;
    });
  }

  void _startDemoMode() async {
    await ble.disconnect();
    demo.start();
    setState(() {
      demoMode = true;
      tab = 1;
    });
  }

  void _stopDemoMode() {
    demo.stop();
    setState(() {
      demoMode = false;
    });
  }

  @override
  void dispose() {
    ble.dispose();
    demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!thresholdsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
  ScanConnectPage(
    ble: ble,
    demoMode: demoMode,
    onStartDemoMode: _startDemoMode,
    onStopDemoMode: _stopDemoMode,
  ),
  DashboardPage(
    ble: ble,
    thresholds: thresholds,
    sampleStream: activeSampleStream,
    demoMode: demoMode,
  ),
HistoryPage(
  demoMode: demoMode,
),
  SettingsPage(
    initial: thresholds,
    onSave: (t) async {
      await store.save(t);
      setState(() => thresholds = t);
    },
  ),
];
    return Scaffold(
  body: IndexedStack(
    index: tab,
    children: pages,
  ),
  bottomNavigationBar: NavigationBar(
    selectedIndex: tab,
    onDestinationSelected: (i) => setState(() => tab = i),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.bluetooth_searching),
        label: 'Connect',
      ),
      NavigationDestination(
        icon: Icon(Icons.speed),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.history),
        label: 'History',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ],
  ),
);
  }
}