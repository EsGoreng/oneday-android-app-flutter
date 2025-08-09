import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oneday/core/providers/profile_provider.dart';
import 'package:oneday/core/services/widget_updater_services.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../../features/finance/pages/finance_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';


String formatCurrency(double amount, String locale, String symbol) {
  final currencyFormatter = NumberFormat.currency(
    locale: locale,
    symbol: '$symbol ',
    decimalDigits: 0,
  );
  return currencyFormatter.format(amount);
}

class TransactionProvider with ChangeNotifier {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileProvider? _profileProvider;

  String formatCurrency(double amount, String locale, String symbol) {
  final currencyFormatter = NumberFormat.currency(
    locale: locale,
    symbol: '$symbol ',
    decimalDigits: 0,
  );
  return currencyFormatter.format(amount);
}


  String get currencyLocale => _profileProvider?.currencyLocale ?? 'id_ID';
  String get currencySymbol => _profileProvider?.currencySymbol ?? 'Rp';

  void updateProfileProvider(ProfileProvider profileProvider) {
    _profileProvider = profileProvider;
    notifyListeners();
  }
  
  List<Transaction> _transactions = [];
  StreamSubscription<QuerySnapshot>? _transactionSubscription;

  List<Transaction> get transactions {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    return [..._transactions];
  }

  TransactionProvider() {
    // Dengarkan perubahan status login
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToTransactions(user.uid);
      } else {
        // Jika user logout, bersihkan data dan batalkan listener
        _transactionSubscription?.cancel();
        _transactions = [];
        notifyListeners();
      }
    });
  }

  // Mendengarkan data transaksi dari Firestore secara real-time
  void listenToTransactions(String userId) {
    _transactionSubscription?.cancel();
    _transactionSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .snapshots()
        .listen((snapshot) {
      _transactions = snapshot.docs.map((doc) {
        return Transaction.fromMap(doc.data(), doc.id);
      }).toList();
      notifyListeners();
      updateBalanceWidget(this);  // Beri tahu UI bahwa ada data baru
    }, onError: (error) {
      debugPrint("Error listening to transactions: $error");
    });
  }

  Future<void> addTransaction(Transaction transaction) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(transaction.toMap());
    } catch (e) {
      debugPrint("Error adding transaction: $e");
      // Tambahkan error handling untuk UI di sini
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      debugPrint("Error updating transaction: $e");
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting transaction: $e");
    }
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  DateTimeRange _getDateRangeForRecurringPeriod(BudgetPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.daily:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
      case BudgetPeriod.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startDate = DateTime(start.year, start.month, start.day);
        return DateTimeRange(start: startDate, end: startDate.add(const Duration(days: 7)));
      case BudgetPeriod.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(start: start, end: end.add(const Duration(days: 1)));
      case BudgetPeriod.yearly:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31);
        return DateTimeRange(start: start, end: end.add(const Duration(days: 1)));
    }
  }

  List<Transaction> getTransactionsForCategory({
    required String categoryName,
    required BudgetPeriod periodicity,
    DateTime? targetMonth,
  }) {
    DateTimeRange dateRange;
    if (targetMonth != null) {
      dateRange = DateTimeRange(
        start: DateTime(targetMonth.year, targetMonth.month, 1),
        end: DateTime(targetMonth.year, targetMonth.month + 1, 1),
      );
    } else {
      dateRange = _getDateRangeForRecurringPeriod(periodicity);
    }
    return _transactions
        .where((tx) =>
            tx.category == categoryName &&
            tx.type == TransactionType.expense &&
            tx.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(dateRange.end))
        .toList();
  }

  Future<void> deleteMultipleTransactions(Set<String> ids) async {
    final user = _auth.currentUser;
    if (user == null || ids.isEmpty) return;

    // Gunakan WriteBatch untuk efisiensi.
    // Ini menggabungkan semua operasi hapus menjadi satu panggilan ke server.
    final batch = _firestore.batch();
    final collectionRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    for (final id in ids) {
      batch.delete(collectionRef.doc(id));
    }

    try {
      await batch.commit();
      // Tidak perlu `notifyListeners()` karena stream akan mendeteksi perubahan
      // dan memperbarui UI secara otomatis.
    } catch (e) {
      debugPrint("Error deleting multiple transactions: $e");
      // Anda bisa menambahkan logic untuk menampilkan error ke pengguna di sini.
    }
  }

  List<Transaction> getTransactionsForTimeRange(
      TimeRange timeRange, [DateTimeRange? customRange]) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (timeRange == TimeRange.custom && customRange != null) {
      start = customRange.start;
      end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
    } else {
      switch (timeRange) {
        case TimeRange.daily:
          start = DateTime(now.year, now.month, now.day);
          end = start.add(const Duration(days: 1));
          break;
        case TimeRange.monthly:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 1);
          break;
        case TimeRange.yearly:
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year + 1, 1, 1);
          break;
        case TimeRange.custom:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 1);
          break;
      }
    }

    return _transactions
        .where((tx) =>
            !tx.date.isBefore(start) && tx.date.isBefore(end))
        .toList();
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Menghitung total pengeluaran dari semua transaksi
  double get totalExpenses {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Menghitung saldo saat ini
  double get currentBalance {
    return totalIncome - totalExpenses;
  }

}