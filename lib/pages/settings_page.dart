import 'package:flutter/material.dart';
import '../models/thresholds.dart';

class SettingsPage extends StatefulWidget {
  final Thresholds initial;
  final Future<void> Function(Thresholds) onSave;

  const SettingsPage({super.key, required this.initial, required this.onSave});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController eco2Ok;
  late TextEditingController eco2Bad;
  late TextEditingController tvocOk;
  late TextEditingController tvocBad;

  String msg = "";

  @override
  void initState() {
    super.initState();
    eco2Ok = TextEditingController(text: widget.initial.eco2Ok.toString());
    eco2Bad = TextEditingController(text: widget.initial.eco2Bad.toString());
    tvocOk = TextEditingController(text: widget.initial.tvocOk.toString());
    tvocBad = TextEditingController(text: widget.initial.tvocBad.toString());
  }

  @override
  void dispose() {
    eco2Ok.dispose();
    eco2Bad.dispose();
    tvocOk.dispose();
    tvocBad.dispose();
    super.dispose();
  }

  int? _parse(TextEditingController c) {
    return int.tryParse(c.text.trim());
  }

  Future<void> _save() async {
    final a = _parse(eco2Ok);
    final b = _parse(eco2Bad);
    final c = _parse(tvocOk);
    final d = _parse(tvocBad);

    if ([a, b, c, d].any((x) => x == null)) {
      setState(() => msg = "Please enter valid integers.");
      return;
    }
    if (!(a! < b! && c! < d!)) {
      setState(() => msg = "Need eco2Ok < eco2Bad AND tvocOk < tvocBad.");
      return;
    }

    final t = Thresholds(eco2Ok: a, eco2Bad: b, tvocOk: c, tvocBad: d);
    await widget.onSave(t);
    setState(() => msg = "Saved.");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: Text("eCO₂ thresholds (ppm)")),
                    const SizedBox(height: 8),
                    _field("eco2Ok (Good <)", eco2Ok),
                    _field("eco2Bad (OK <)", eco2Bad),
                    const SizedBox(height: 12),
                    const Align(alignment: Alignment.centerLeft, child: Text("TVOC thresholds (ppb)")),
                    const SizedBox(height: 8),
                    _field("tvocOk (Good <)", tvocOk),
                    _field("tvocBad (OK <)", tvocBad),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text("Save"),
            ),
            const SizedBox(height: 8),
            if (msg.isNotEmpty) Text(msg),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}