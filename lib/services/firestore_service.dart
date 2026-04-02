import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/iaq_sample.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveReading(IaqSample sample) async {
    await _db.collection('iaq_readings').add({
      'eco2': sample.eco2,
      'tvoc': sample.tvoc,
      'deviceTime': sample.t,
      'receivedAt': FieldValue.serverTimestamp(),
      'status': _status(sample.eco2, sample.tvoc),
    });
  }

  String _status(int eco2, int tvoc) {
    if (eco2 >= 1200 || tvoc >= 300) return 'bad';
    if (eco2 >= 800 || tvoc >= 150) return 'ok';
    return 'good';
  }
}