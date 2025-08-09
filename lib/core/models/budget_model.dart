import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BudgetPeriod { daily, weekly, monthly, yearly }

extension BudgetPeriodExtension on BudgetPeriod {
  String get displayName {
    switch (this) {
      case BudgetPeriod.daily: return 'Daily';
      case BudgetPeriod.weekly: return 'Weekly';
      case BudgetPeriod.monthly: return 'Monthly';
      case BudgetPeriod.yearly: return 'Yearly';
      }
  }
}

class Budget {
  final String id;
  final String categoryName;
  final IconData categoryIcon;
  final double budgetedAmount;
  final BudgetPeriod periodicity;
  final DateTime? targetMonth; // Jika null, berarti budget berulang

  const Budget({
    required this.id,
    required this.categoryName,
    required this.categoryIcon,
    required this.budgetedAmount,
    required this.periodicity,
    this.targetMonth,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'categoryIcon': {
        'codePoint': categoryIcon.codePoint,
        'fontFamily': categoryIcon.fontFamily,
      },
      'budgetedAmount': budgetedAmount,
      'periodicity': periodicity.toString().split('.').last, // Simpan enum sebagai string
      'targetMonth': targetMonth != null ? Timestamp.fromDate(targetMonth!) : null,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String documentId) {
    return Budget(
      id: documentId,
      categoryName: map['categoryName'] ?? '',
      categoryIcon: IconData(
        map['categoryIcon']['codePoint'] ?? Icons.error.codePoint,
        fontFamily: map['categoryIcon']['fontFamily'],
      ),
      budgetedAmount: (map['budgetedAmount'] ?? 0.0).toDouble(),
      periodicity: BudgetPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == map['periodicity'],
        orElse: () => BudgetPeriod.monthly, // Default value
      ),
      targetMonth: (map['targetMonth'] as Timestamp?)?.toDate(),
    );
  }
}




class BudgetSummary {
  final String name;
  final IconData icon;
  final double budgeted;
  final double spent;
  final BudgetPeriod periodicity;
  final DateTime? targetMonth;

  BudgetSummary({
    required this.name,
    required this.icon,
    required this.budgeted,
    required this.spent,
    required this.periodicity,
    this.targetMonth,
  });
}