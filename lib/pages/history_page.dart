import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final bool demoMode;

  const HistoryPage({
    super.key,
    required this.demoMode,
  });

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "No timestamp";
    final dt = ts.toDate().toLocal();
    return "${dt.year.toString().padLeft(4, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}:"
        "${dt.second.toString().padLeft(2, '0')}";
  }

  Color _statusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'good':
        return const Color(0xFF2E7D32);
      case 'ok':
        return const Color(0xFFEF6C00);
      case 'bad':
        return const Color(0xFFC62828);
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Clear Firestore history?"),
            content: const Text(
              "This will delete all documents in iaq_readings. This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('iaq_readings').get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Firestore history cleared.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('iaq_readings')
        .orderBy('receivedAt', descending: true)
        .limit(200)
        .snapshots();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              demoMode ? "History (Demo Mode)" : "History (Live Mode)",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              "Reading history is loaded directly from Firebase Firestore.",
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Card(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "Failed to load Firestore data:\n${snapshot.error}",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Card(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("No Firestore history yet."),
                        ),
                      ),
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();

                        final eco2 = data['eco2'] ?? '-';
                        final tvoc = data['tvoc'] ?? '-';
                        final status = (data['status'] ?? 'unknown').toString();
                        final receivedAt = data['receivedAt'] as Timestamp?;
                        final deviceTime = data['deviceTime'] ?? '-';

                        return ListTile(
                          title: Text("eCO₂ $eco2 ppm  |  TVOC $tvoc ppb"),
                          subtitle: Text(
                            "${_formatTime(receivedAt)}  |  deviceTime=$deviceTime",
                          ),
                          trailing: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status, context),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _clearAll(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text("Clear Firestore history"),
            ),
          ],
        ),
      ),
    );
  }
}//done
