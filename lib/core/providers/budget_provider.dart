import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneday/core/providers/transaction_provider.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TransactionProvider? _transactionProvider;

  List<Budget> _budgets = [];
  StreamSubscription<QuerySnapshot>? _budgetSubscription;
  
  List<Budget> get budgets => _budgets;

  BudgetProvider(this._transactionProvider) {
    // Dengarkan perubahan status otentikasi
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToBudgets(user.uid);
      } else {
        _budgetSubscription?.cancel();
        _budgets = [];
        notifyListeners();
      }
    });
  }

  void listenToBudgets(String userId) {
    _budgetSubscription?.cancel();
    _budgetSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .snapshots()
        .listen((snapshot) {
      _budgets = snapshot.docs.map((doc) => Budget.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to budgets: $error");
    });
  }

  

  Future<void> addOrUpdateBudget({
    required String categoryName,
    required IconData icon,
    required double amount,
    required BudgetPeriod periodicity,
    DateTime? targetMonth,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final collectionRef = _firestore.collection('users').doc(user.uid).collection('budgets');

    // Buat query untuk mencari budget yang cocok
    Query query = collectionRef
        .where('categoryName', isEqualTo: categoryName)
        .where('periodicity', isEqualTo: periodicity.toString().split('.').last);

    if (targetMonth != null) {
      query = query.where('targetMonth', isEqualTo: Timestamp.fromDate(targetMonth));
    } else {
      query = query.where('targetMonth', isNull: true);
    }
    
    final querySnapshot = await query.limit(1).get();

    final newBudget = Budget(
      id: '', // ID sementara, akan di-generate oleh Firestore jika baru
      categoryName: categoryName,
      categoryIcon: icon,
      budgetedAmount: amount,
      periodicity: periodicity,
      targetMonth: targetMonth,
    );

    try {
      if (querySnapshot.docs.isNotEmpty) {
        // Jika ada, update budget yang sudah ada
        final docId = querySnapshot.docs.first.id;
        await collectionRef.doc(docId).update(newBudget.toMap());
      } else {
        // Jika tidak ada, tambahkan sebagai budget baru
        await collectionRef.add(newBudget.toMap());
      }
    } catch (e) {
      debugPrint("Error adding or updating budget: $e");
    }
  }

  

  Future<void> deleteBudget({
    required String categoryName,
    required BudgetPeriod periodicity,
    DateTime? targetMonth,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final collectionRef = _firestore.collection('users').doc(user.uid).collection('budgets');

    Query query = collectionRef
        .where('categoryName', isEqualTo: categoryName)
        .where('periodicity', isEqualTo: periodicity.toString().split('.').last);
        
    if (targetMonth != null) {
      query = query.where('targetMonth', isEqualTo: Timestamp.fromDate(targetMonth));
    } else {
      query = query.where('targetMonth', isNull: true);
    }

    try {
      final querySnapshot = await query.limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await collectionRef.doc(docId).delete();
      }
    } catch (e) {
      debugPrint("Error deleting budget: $e");
    }
  }

  void updateDependencies(TransactionProvider newTransactionProvider) {
    _transactionProvider = newTransactionProvider;
    notifyListeners(); // Panggil notifyListeners agar summary di-recalculate
  }
  
  // Semua fungsi getter di bawah ini seharusnya bekerja tanpa perubahan,
  // karena mereka beroperasi pada list `_budgets` yang sekarang sudah real-time.

  List<BudgetSummary> getBudgetSummariesForPeriod(BudgetPeriod period) {
    final dateRange = _getDateRangeForRecurringPeriod(period);
    final relevantBudgets =
        _budgets.where((b) => b.periodicity == period && b.targetMonth == null).toList();
    return relevantBudgets.map((budget) {
      final spentAmount = _getSpentAmountForDateRange(budget.categoryName, dateRange);
      return BudgetSummary(
        name: budget.categoryName,
        icon: budget.categoryIcon,
        budgeted: budget.budgetedAmount,
        spent: spentAmount,
        periodicity: budget.periodicity,
        targetMonth: budget.targetMonth,
      );
    }).toList();
  }

  List<BudgetSummary> get specificMonthBudgetSummaries {
    final specificBudgets = _budgets.where((b) => b.targetMonth != null).toList();
    specificBudgets.sort((a, b) => b.targetMonth!.compareTo(a.targetMonth!));
    return specificBudgets.map((budget) {
      final target = budget.targetMonth!;
      final dateRange = DateTimeRange(
        start: DateTime(target.year, target.month, 1),
        end: DateTime(target.year, target.month + 1, 1),
      );
      final spentAmount = _getSpentAmountForDateRange(budget.categoryName, dateRange);
      return BudgetSummary(
        name: budget.categoryName,
        icon: budget.categoryIcon,
        budgeted: budget.budgetedAmount,
        spent: spentAmount,
        periodicity: budget.periodicity,
        targetMonth: budget.targetMonth,
      );
    }).toList();
  }

  double _getSpentAmountForDateRange(String categoryName, DateTimeRange dateRange) {
    if (_transactionProvider == null) return 0.0;
    return _transactionProvider!.transactions
        .where((tx) =>
            tx.type == TransactionType.expense &&
            tx.category == categoryName &&
            tx.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(dateRange.end))
        .fold(0.0, (sum, item) => sum + item.amount);
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

  @override
  void dispose() {
    _budgetSubscription?.cancel();
    super.dispose();
  }
}