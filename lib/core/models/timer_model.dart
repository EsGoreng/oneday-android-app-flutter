class TimerModel {
  String id;
  String name;
  String? description;
  int duration; // dalam menit

  TimerModel({
    required this.id,
    this.description,
    required this.name,
    required this.duration,
  });

  // Konversi objek TimerModel ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'duration': duration,
    };
  }

  // Buat objek TimerModel dari Map Firestore
  factory TimerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TimerModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'],
      duration: map['duration'] ?? 1,
    );
  }
}
