import 'package:cloud_firestore/cloud_firestore.dart';


class SavingTransaction {
  final String id;
  final double amount;
  final DateTime date;

  SavingTransaction({
    required this.id,
    required this.amount,
    required this.date,
  });

  // Konversi objek ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }

  // Buat objek dari Map Firestore
  factory SavingTransaction.fromMap(Map<String, dynamic> map) {
    return SavingTransaction(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  SavingTransaction copyWith({
    double? amount,
    DateTime? date,
  }) {
    return SavingTransaction(
      id: id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}

enum SavingRangeType { daily, weekly, monthly }

class Savingplan {
  final String id;
  final String name;
  final double target;
  final double filling;
  final SavingRangeType rangeType;
  final List<SavingTransaction> transactions;

  Savingplan({
    required this.id,
    required this.name,
    required this.target,
    required this.filling,
    required this.rangeType,
    this.transactions = const [],
  });

  // Konversi objek ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'target': target,
      'filling': filling,
      'rangeType': rangeType.toString().split('.').last,
      'transactions': transactions.map((tx) => tx.toMap()).toList(),
    };
  }

  // Buat objek dari Map Firestore
  factory Savingplan.fromMap(Map<String, dynamic> map, String documentId) {
    var transactionsFromDb = map['transactions'] as List<dynamic>? ?? [];
    List<SavingTransaction> transactionList = transactionsFromDb
        .map((txMap) => SavingTransaction.fromMap(txMap as Map<String, dynamic>))
        .toList();

    return Savingplan(
      id: documentId,
      name: map['name'] ?? '',
      target: (map['target'] ?? 0.0).toDouble(),
      filling: (map['filling'] ?? 0.0).toDouble(),
      rangeType: SavingRangeType.values.firstWhere(
        (e) => e.toString().split('.').last == map['rangeType'],
        orElse: () => SavingRangeType.daily,
      ),
      transactions: transactionList,
    );
  }

  Savingplan copyWith({
    String? name,
    double? target,
    double? filling,
    SavingRangeType? rangeType,
    List<SavingTransaction>? transactions,
  }) {
    return Savingplan(
      id: id,
      name: name ?? this.name,
      target: target ?? this.target,
      filling: filling ?? this.filling,
      rangeType: rangeType ?? this.rangeType,
      transactions: transactions ?? this.transactions,
    );
  }
}
