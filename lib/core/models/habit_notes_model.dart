import 'package:cloud_firestore/cloud_firestore.dart';

// Nama model diubah menjadi lebih spesifik untuk menghindari konflik
class HabitNote {
  final String id;
  final String noteName;
  final DateTime noteDate;
  final String note;

  HabitNote({
    required this.id,
    required this.noteName,
    required this.noteDate,
    required this.note,
  });

  // Konversi objek HabitNote ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'noteName': noteName,
      'noteDate': Timestamp.fromDate(noteDate),
      'note': note,
    };
  }

  // Buat objek HabitNote dari Map Firestore
  factory HabitNote.fromMap(Map<String, dynamic> map, String documentId) {
    return HabitNote(
      id: documentId,
      noteName: map['noteName'] ?? '',
      noteDate: (map['noteDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] ?? '',
    );
  }
}
