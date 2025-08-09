import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import '../../shared/widgets/common_widgets.dart';

enum MoodCategory { awful, bad, meh, smile, happy }

extension MoodCategoryExtension on MoodCategory {
  String get moodName {
    // ... (logika ini tidak berubah)
    switch (this) {
      case MoodCategory.awful: return 'Awful';
      case MoodCategory.bad: return 'Bad';
      case MoodCategory.meh: return 'Meh';
      case MoodCategory.smile: return 'Good';
      case MoodCategory.happy: return 'Happy';
    }
  }

  Color get color {
    // ... (logika ini tidak berubah)
    switch (this) {
      case MoodCategory.awful: return customGreen;
      case MoodCategory.bad: return customRed;
      case MoodCategory.meh: return Colors.blueGrey.shade200;
      case MoodCategory.smile: return customYellow;
      case MoodCategory.happy: return customPink;
    }
  }

  String get imagePath {
    // ... (logika ini tidak berubah)
    switch (this) {
      case MoodCategory.awful: return 'images/mood_emoticon/awful.png';
      case MoodCategory.bad: return 'images/mood_emoticon/bad.png';
      case MoodCategory.meh: return 'images/mood_emoticon/meh.png';
      case MoodCategory.smile: return 'images/mood_emoticon/smile.png';
      case MoodCategory.happy: return 'images/mood_emoticon/happy.png';
    }
  }
}

class Mood {
  final String id;
  final MoodCategory moodCategory;
  final DateTime date;

  Mood({
    required this.id,
    required this.moodCategory,
    required this.date,
  });

  String get moodName => moodCategory.moodName;

  // Konversi objek Mood ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'moodCategory': moodCategory.toString().split('.').last, // Simpan enum sebagai string
      'date': Timestamp.fromDate(date),
    };
  }

  // Buat objek Mood dari Map Firestore
  factory Mood.fromMap(Map<String, dynamic> map, String documentId) {
    return Mood(
      id: documentId,
      moodCategory: MoodCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['moodCategory'],
        orElse: () => MoodCategory.meh, // Nilai default jika ada error
      ),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
