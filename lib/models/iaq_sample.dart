class IaqSample {
  final int eco2; // ppm
  final int tvoc; // ppb
  final int t; // millis from device
  final DateTime receivedAt;

  IaqSample({
    required this.eco2,
    required this.tvoc,
    required this.t,
    required this.receivedAt,
  });

  static IaqSample? fromJsonLine(String line) {
    try {
      final s = line.trim();
      if (!s.startsWith('{') || !s.endsWith('}')) return null;

      // 极简 JSON 解析：只解析 eco2/tvoc/t 三个数字字段
      final body = s.substring(1, s.length - 1);
      final parts = body.split(',');
      final map = <String, String>{};
      for (final p in parts) {
        final kv = p.split(':');
        if (kv.length != 2) continue;
        final k = kv[0].trim().replaceAll('"', '');
        final v = kv[1].trim().replaceAll('"', '');
        map[k] = v;
      }

      if (!map.containsKey('eco2') || !map.containsKey('tvoc') || !map.containsKey('t')) {
        return null;
      }

      return IaqSample(
        eco2: int.parse(map['eco2']!),
        tvoc: int.parse(map['tvoc']!),
        t: int.parse(map['t']!),
        receivedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}