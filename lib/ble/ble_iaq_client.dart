import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/iaq_sample.dart';

class BleIaqClient {
  static const String targetName = "IAQ-SGP30";

  static final Guid serviceUuid =
      Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");

  static final Guid notifyCharUuid =
      Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

  BluetoothDevice? _device;
  BluetoothCharacteristic? _notifyChar;

  final _connectedCtrl = StreamController<bool>.broadcast();
  Stream<bool> get connected => _connectedCtrl.stream;

  final _sampleCtrl = StreamController<IaqSample>.broadcast();
  Stream<IaqSample> get samples => _sampleCtrl.stream;

  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connStateSub;

  final StringBuffer _lineBuf = StringBuffer();

  Timer? _demoTimer;
  final Random _random = Random();
  bool _demoMode = false;

  bool get demoMode => _demoMode;

  Future<void> ensureBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      throw Exception("Bluetooth is not ON");
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    await stopDemo();
    await disconnect();

    _device = device;

    try {
      await device.connect(
        timeout: const Duration(seconds: 12),
        autoConnect: false,
      );
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (!s.contains("already connected")) {
        rethrow;
      }
    }

    _connStateSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectedCtrl.add(false);
      }
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final services = await device.discoverServices();

    BluetoothService? targetService;
    for (final s in services) {
      if (s.serviceUuid == serviceUuid) {
        targetService = s;
        break;
      }
    }

    if (targetService == null) {
      throw Exception("Target BLE service not found");
    }

    BluetoothCharacteristic? targetChar;
    for (final c in targetService.characteristics) {
      if (c.characteristicUuid == notifyCharUuid) {
        targetChar = c;
        break;
      }
    }

    if (targetChar == null) {
      throw Exception("Target notify characteristic not found");
    }

    _notifyChar = targetChar;

    await _notifyChar!.setNotifyValue(true);
    await Future.delayed(const Duration(milliseconds: 200));

    _notifySub = _notifyChar!.lastValueStream.listen((bytes) {
      try {
        final chunk = utf8.decode(bytes, allowMalformed: true);
        _lineBuf.write(chunk);

        var text = _lineBuf.toString();
        int idx;

        while ((idx = text.indexOf('\n')) != -1) {
          final line = text.substring(0, idx).trim();
          text = text.substring(idx + 1);

          if (line.isEmpty) continue;

          final sample = IaqSample.fromJsonLine(line);
          if (sample != null) {
            _sampleCtrl.add(sample);
          }
        }

        _lineBuf
          ..clear()
          ..write(text);
      } catch (_) {
        // ignore malformed packets
      }
    });

    _connectedCtrl.add(true);
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;

    await _connStateSub?.cancel();
    _connStateSub = null;

    try {
      if (_notifyChar != null) {
        await _notifyChar!.setNotifyValue(false);
      }
    } catch (_) {}

    _notifyChar = null;

    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
      _device = null;
    }

    _lineBuf.clear();
    _connectedCtrl.add(false);
  }

  Future<void> startDemo() async {
    await disconnect();
    await stopDemo();

    _demoMode = true;
    _connectedCtrl.add(true);

    int eco2 = 520;
    int tvoc = 70;
    int tick = 0;

    _demoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      tick++;

      // 平滑波动
      eco2 += _random.nextInt(31) - 15;
      tvoc += _random.nextInt(13) - 6;

      // 偶发高值事件
      if (tick % 20 == 0) {
        eco2 += 180 + _random.nextInt(120);
        tvoc += 40 + _random.nextInt(30);
      }

      // 慢慢回落
      if (eco2 > 650) eco2 -= 10;
      if (tvoc > 100) tvoc -= 4;

      eco2 = eco2.clamp(420, 1600);
      tvoc = tvoc.clamp(10, 420);

      _sampleCtrl.add(
        IaqSample(
          eco2: eco2,
          tvoc: tvoc,
          t: DateTime.now().millisecondsSinceEpoch,
          receivedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> stopDemo() async {
    _demoTimer?.cancel();
    _demoTimer = null;
    _demoMode = false;
    _connectedCtrl.add(false);
  }

  void dispose() {
    _demoTimer?.cancel();
    _notifySub?.cancel();
    _connStateSub?.cancel();
    _connectedCtrl.close();
    _sampleCtrl.close();
  }
}