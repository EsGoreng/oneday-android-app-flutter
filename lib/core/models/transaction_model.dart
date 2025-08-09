import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum untuk menentukan jenis transaksi
enum TransactionType { income, expense }

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String category; // Nanti bisa diganti dengan model Category
  final IconData categoryIcon; // Ikon untuk kategori
  final String note;
  final DateTime date;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.categoryIcon,
    required this.note,
    required this.date,
  });

  // Konversi dari objek Transaction ke Map untuk disimpan di Firestore
  Map<String, dynamic>toMap() {
    return {
      'amount':amount,
      // Simpan enum sebagai string
      'type' : type.toString().split('.').last,
      'category' : category,
      // Simpan IconData sebagai Map
      'categoryIcon' : {
        'codePoint' : categoryIcon.codePoint,
        'fontFamily': categoryIcon.fontFamily,
      },
      'note' : note,
      'date' : Timestamp.fromDate(date),
    };
  }

  // Buat objek Transaction dari Map (data dari Firestore)
  factory Transaction.fromMap(Map<String, dynamic> map, String  documentId) {
    return Transaction(
      id: documentId,
      amount: (map['amount'] ?? 0).toDouble(),
      // Ubah string kembali ke enum
      type: (map['type'] == 'income') ? TransactionType.income : TransactionType.expense,
      category: map['category'] ?? '',
      categoryIcon: IconData(
        map['categoryIcon']['codePoint'] ?? 0,
        fontFamily: map ['categoryIcon']['fontFamily'],
      ),
      note: map['note'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

}

