enum AirState { good, ok, bad }

class Thresholds {
  final int eco2Ok;
  final int eco2Bad;
  final int tvocOk;
  final int tvocBad;

  const Thresholds({
    required this.eco2Ok,
    required this.eco2Bad,
    required this.tvocOk,
    required this.tvocBad,
  });

  factory Thresholds.defaults() => const Thresholds(
        eco2Ok: 800,
        eco2Bad: 1200,
        tvocOk: 150,
        tvocBad: 300,
      );

  AirState classifyEco2(int eco2) {
    if (eco2 < eco2Ok) return AirState.good;
    if (eco2 < eco2Bad) return AirState.ok;
    return AirState.bad;
  }

  AirState classifyTvoc(int tvoc) {
    if (tvoc < tvocOk) return AirState.good;
    if (tvoc < tvocBad) return AirState.ok;
    return AirState.bad;
  }

  AirState overall({required int eco2, required int tvoc}) {
    final a = classifyEco2(eco2);
    final b = classifyTvoc(tvoc);
    return a.index > b.index ? a : b;
  }

  String suggestion(AirState s) {
    switch (s) {
      case AirState.good:
        return "Air looks good. Keep current ventilation.";
      case AirState.ok:
        return "Consider opening a window for 5–10 minutes.";
      case AirState.bad:
        return "Air is poor. Ventilate now and reduce indoor sources (cooking/spray).";
    }
  }

  String stateText(AirState s) {
    switch (s) {
      case AirState.good:
        return "Good";
      case AirState.ok:
        return "OK";
      case AirState.bad:
        return "Bad";
    }
  }

  Thresholds copyWith({
    int? eco2Ok,
    int? eco2Bad,
    int? tvocOk,
    int? tvocBad,
  }) {
    return Thresholds(
      eco2Ok: eco2Ok ?? this.eco2Ok,
      eco2Bad: eco2Bad ?? this.eco2Bad,
      tvocOk: tvocOk ?? this.tvocOk,
      tvocBad: tvocBad ?? this.tvocBad,
    );
  }
}