import 'package:cloud_firestore/cloud_firestore.dart';

// Nama model diubah menjadi lebih spesifik untuk menghindari konflik
class MoodNote {
  final String id;
  final String noteName;
  final DateTime noteDate;
  final String note;

  MoodNote({
    required this.id,
    required this.noteName,
    required this.noteDate,
    required this.note,
  });

  // Konversi objek MoodNote ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'noteName': noteName,
      'noteDate': Timestamp.fromDate(noteDate),
      'note': note,
    };
  }

  // Buat objek MoodNote dari Map Firestore
  factory MoodNote.fromMap(Map<String, dynamic> map, String documentId) {
    return MoodNote(
      id: documentId,
      noteName: map['noteName'] ?? '',
      noteDate: (map['noteDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] ?? '',
    );
  }
}
