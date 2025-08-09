import 'package:flutter/material.dart';

enum CategoryType {
  expense,
  income,
}

class CategoryInfo {
  final String id; // ID Dokumen dari Firestore
  final String name;
  final IconData icon;
  final CategoryType type;

  const CategoryInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  // Konversi objek CategoryInfo ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': {
        'codePoint': icon.codePoint,
        'fontFamily': icon.fontFamily,
        'fontPackage': icon.fontPackage,
      },
      'type': type.name
    };
  }

  // Buat objek CategoryInfo dari Map Firestore
  factory CategoryInfo.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryInfo(
      id: documentId,
      name: map['name'] ?? '',
      icon: IconData(
        map['icon']['codePoint'] ?? Icons.error.codePoint,
        fontFamily: map['icon']['fontFamily'],
        fontPackage: map['icon']['fontPackage'],
      ),
      type: CategoryType.values.firstWhere((e) => e.name == map ['type'],
      orElse: () => CategoryType.expense,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryInfo && 
    other.id == id && 
    other.name == name &&
    other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ type.hashCode;
}
