import 'dart:async';
import 'package:flutter/material.dart';

import '../ble/ble_iaq_client.dart';
import '../models/iaq_sample.dart';
import '../models/thresholds.dart';
import '../widgets/iaq_gauge.dart';
import '../services/firestore_service.dart';

class DashboardPage extends StatefulWidget {
  final BleIaqClient ble;
  final Thresholds thresholds;
  final Stream<IaqSample> sampleStream;
  final bool demoMode;

  const DashboardPage({
    super.key,
    required this.ble,
    required this.thresholds,
    required this.sampleStream,
    required this.demoMode,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  IaqSample? latest;
  StreamSubscription<IaqSample>? sub;

  final FirestoreService firestore = FirestoreService();
  DateTime? _lastUploadTime;

  @override
  void initState() {
    super.initState();
    _bindStream();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sampleStream != widget.sampleStream) {
      sub?.cancel();
      _bindStream();
    }
  }

  void _bindStream() {
    sub = widget.sampleStream.listen((s) async {
      setState(() => latest = s);

      final now = DateTime.now();
      if (_lastUploadTime == null ||
          now.difference(_lastUploadTime!).inSeconds >= 10) {
        _lastUploadTime = now;
        await firestore.saveReading(s);
      }
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = latest;
    final eco2 = s?.eco2 ?? 0;
    final tvoc = s?.tvoc ?? 0;

    final overall = s == null
        ? null
        : widget.thresholds.overall(eco2: eco2, tvoc: tvoc);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.demoMode ? "Dashboard (Demo Mode)" : "Dashboard (Live Mode)",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overall == null
                          ? "Waiting for data..."
                          : "Status: ${widget.thresholds.stateText(overall)}",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overall == null
                          ? "Connect the sensor or start demo mode."
                          : widget.thresholds.suggestion(overall),
                    ),
                    const SizedBox(height: 8),
                    if (s != null)
                      Text("Last update: ${s.receivedAt.toLocal()}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    IaqGauge(
                      value: eco2.toDouble(),
                      min: 400,
                      max: 2000,
                      segments: const [
                        GaugeSegment(from: 400, to: 800, color: Color(0xFF4CAF50)),
                        GaugeSegment(from: 800, to: 1200, color: Color(0xFFFFA726)),
                        GaugeSegment(from: 1200, to: 2000, color: Color(0xFFEF5350)),
                      ],
                      label: "eCO₂ (ppm)",
                      valueText: s == null ? "-" : "$eco2",
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Thresholds: <${widget.thresholds.eco2Ok} good, <${widget.thresholds.eco2Bad} ok, else bad",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    IaqGauge(
                      value: tvoc.toDouble(),
                      min: 0,
                      max: 600,
                      segments: const [
                        GaugeSegment(from: 0, to: 150, color: Color(0xFF4CAF50)),
                        GaugeSegment(from: 150, to: 300, color: Color(0xFFFFA726)),
                        GaugeSegment(from: 300, to: 600, color: Color(0xFFEF5350)),
                      ],
                      label: "TVOC (ppb)",
                      valueText: s == null ? "-" : "$tvoc",
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Thresholds: <${widget.thresholds.tvocOk} good, <${widget.thresholds.tvocBad} ok, else bad",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}//done
