import 'package:cloud_firestore/cloud_firestore.dart';

class Notes {
  final String id;
  final String noteName;
  final DateTime noteDate;
  final String note;

  Notes({
    required this.id,
    required this.noteName,
    required this.noteDate,
    required this.note,
  });

  // Konversi objek Notes ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'noteName': noteName,
      'noteDate': Timestamp.fromDate(noteDate),
      'note': note,
    };
  }

  // Buat objek Notes dari Map Firestore
  factory Notes.fromMap(Map<String, dynamic> map, String documentId) {
    return Notes(
      id: documentId,
      noteName: map['noteName'] ?? '',
      noteDate: (map['noteDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] ?? '',
    );
  }
}
