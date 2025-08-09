import 'package:cloud_firestore/cloud_firestore.dart';

class TimerSession {
  final String id;
  final String name;
  final Duration actualDuration;
  final DateTime completedAt;

  TimerSession({
    required this.id,
    required this.name,
    required this.actualDuration,
    required this.completedAt,
  });

  // Konversi objek TimerSession ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'actualDurationInSeconds': actualDuration.inSeconds, // Simpan sebagai integer
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  // Buat objek TimerSession dari Map Firestore
  factory TimerSession.fromMap(Map<String, dynamic> map, String documentId) {
    return TimerSession(
      id: documentId,
      name: map['name'] ?? '',
      actualDuration: Duration(seconds: map['actualDurationInSeconds'] ?? 0),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
