import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneday/core/models/transaction_category_model.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _categorySubscription;

  final List<CategoryInfo> _defaultExpenseCategories = [
    CategoryInfo(id: 'default_food', name: 'Food', icon: Icons.restaurant, type: CategoryType.expense),
    CategoryInfo(id: 'default_transport', name: 'Transport', icon: Icons.local_gas_station, type: CategoryType.expense),
    CategoryInfo(id: 'default_shopping', name: 'Shopping', icon: Icons.shopping_cart, type: CategoryType.expense),
    CategoryInfo(id: 'default_bills', name: 'Bills', icon: Icons.receipt, type: CategoryType.expense),
    CategoryInfo(id: 'default_health', name: 'Health', icon: Icons.health_and_safety, type: CategoryType.expense),
    CategoryInfo(id: 'default_education', name: 'Education', icon: Icons.school, type: CategoryType.expense),
    CategoryInfo(id: 'default_movie', name: 'Movie', icon: Icons.movie, type: CategoryType.expense),
  ];

  final List<CategoryInfo> _defaultIncomeCategories = [
    CategoryInfo(id: 'default_salary', name: 'Salary', icon: Icons.work, type: CategoryType.income),
    CategoryInfo(id: 'default_bonus', name: 'Bonus', icon: Icons.card_giftcard, type: CategoryType.income),
    CategoryInfo(id: 'default_investment', name: 'Investment', icon: Icons.trending_up, type: CategoryType.income),
  ];

  List<CategoryInfo> _customExpenseCategories = [];
  List<CategoryInfo> _customIncomeCategories = [];

  List<CategoryInfo> get defaultExpenseCategories => _defaultExpenseCategories;
  List<CategoryInfo> get defaultIncomeCategories => _defaultIncomeCategories;
  List<CategoryInfo> get customExpenseCategories => _customExpenseCategories;
  List<CategoryInfo> get customIncomeCategories => _customIncomeCategories;

  List<CategoryInfo> get allExpenseCategories => [..._defaultExpenseCategories, ..._customExpenseCategories];
  List<CategoryInfo> get allIncomeCategories => [..._defaultIncomeCategories, ..._customIncomeCategories];
  List<CategoryInfo> get allAvailableCategories => [...allExpenseCategories, ...allIncomeCategories];
  List<CategoryInfo> get allCustomCategories => [..._customExpenseCategories, ..._customIncomeCategories];

  CategoryProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToCustomCategories(user.uid);
      } else {
        _categorySubscription?.cancel();
        _customExpenseCategories = [];
        _customIncomeCategories = [];
        notifyListeners();
      }
    });
  }

  void listenToCustomCategories(String userId) {
    _categorySubscription?.cancel();
    _categorySubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .listen((snapshot) {
      final allCustom = snapshot.docs.map((doc) => CategoryInfo.fromMap(doc.data(), doc.id)).toList();
      
      // Filter kategori custom berdasarkan tipenya
      _customExpenseCategories = allCustom.where((cat) => cat.type == CategoryType.expense).toList();
      _customIncomeCategories = allCustom.where((cat) => cat.type == CategoryType.income).toList();
      
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to categories: $error");
    });
  }

  Future<void> addCustomCategory(CategoryInfo category) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .add(category.toMap());
    } catch (e) {
      debugPrint("Error adding custom category: $e");
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting category: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    super.dispose();
  }
}