import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  String get name {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }
}

class Task {
  String id; // Diubah dari int ke String
  String title;
  String description;
  DateTime date;
  TaskPriority priority;
  bool status;
  String? recurringGroupId;
  List<int>? reminderOffsets;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.priority,
    required this.status,
    this.recurringGroupId,
    this.reminderOffsets,
  });

  // Konversi objek Task ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'priority': priority.toString().split('.').last, // Simpan enum sebagai string
      'status': status,
      'recurringGroupId': recurringGroupId,
      'reminderOffsets': reminderOffsets,
    };
  }

  // Buat objek Task dari Map Firestore
  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => TaskPriority.medium, // Nilai default jika terjadi error
      ),
      status: map['status'] ?? false,
      recurringGroupId: map['recurringGroupId'],
      reminderOffsets: map['reminderOffsets'] != null ? List<int>.from(map['reminderOffsets']) : null,
    );
  }
}
