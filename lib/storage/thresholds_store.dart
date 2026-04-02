import 'package:shared_preferences/shared_preferences.dart';
import '../models/thresholds.dart';

class ThresholdsStore {
  static const _kEco2Ok = "eco2_ok";
  static const _kEco2Bad = "eco2_bad";
  static const _kTvocOk = "tvoc_ok";
  static const _kTvocBad = "tvoc_bad";

  Future<Thresholds> load() async {
    final sp = await SharedPreferences.getInstance();
    final d = Thresholds.defaults();
    return Thresholds(
      eco2Ok: sp.getInt(_kEco2Ok) ?? d.eco2Ok,
      eco2Bad: sp.getInt(_kEco2Bad) ?? d.eco2Bad,
      tvocOk: sp.getInt(_kTvocOk) ?? d.tvocOk,
      tvocBad: sp.getInt(_kTvocBad) ?? d.tvocBad,
    );
  }

  Future<void> save(Thresholds t) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kEco2Ok, t.eco2Ok);
    await sp.setInt(_kEco2Bad, t.eco2Bad);
    await sp.setInt(_kTvocOk, t.tvocOk);
    await sp.setInt(_kTvocBad, t.tvocBad);
  }
}