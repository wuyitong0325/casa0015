import 'dart:async';
import '../models/iaq_sample.dart';

class DemoDataService {
  final _sampleCtrl = StreamController<IaqSample>.broadcast();
  Stream<IaqSample> get samples => _sampleCtrl.stream;

  Timer? _timer;

  int _eco2 = 520;
  int _tvoc = 60;
  int _tick = 0;

  bool _running = false;
  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _running = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick++;

      
      _eco2 += _wave(_tick, 18, 37);
      _tvoc += _wave(_tick, 5, 21);

      // occasionally simulate poor air condition
      if (_tick % 25 == 0) {
        _eco2 += 180;
        _tvoc += 55;
      }

      // drop back gradually
      if (_eco2 > 620) _eco2 -= 8;
      if (_tvoc > 90) _tvoc -= 3;

      // amplitude limit
      _eco2 = _eco2.clamp(420, 1500);
      _tvoc = _tvoc.clamp(10, 420);

      _sampleCtrl.add(
        IaqSample(
          eco2: _eco2,
          tvoc: _tvoc,
          t: DateTime.now().millisecondsSinceEpoch,
          receivedAt: DateTime.now(),
        ),
      );
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  int _wave(int tick, int amp, int period) {
    final phase = tick % period;
    if (phase < period ~/ 2) {
      return amp ~/ (period ~/ 2);
    } else {
      return -(amp ~/ (period ~/ 2));
    }
  }

  void dispose() {
    stop();
    _sampleCtrl.close();
  }
}