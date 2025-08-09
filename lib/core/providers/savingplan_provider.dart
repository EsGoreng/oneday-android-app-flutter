import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/savingplan_model.dart';

class SavingplanProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Savingplan> _savingplans = [];
  StreamSubscription<QuerySnapshot>? _savingplanSubscription;

  List<Savingplan> get savingplans => _savingplans;

  SavingplanProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToSavingPlans(user.uid);
      } else {
        _savingplanSubscription?.cancel();
        _savingplans = [];
        notifyListeners();
      }
    });
  }

  void listenToSavingPlans(String userId) {
    _savingplanSubscription?.cancel();
    _savingplanSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('saving_plans')
        .snapshots()
        .listen((snapshot) {
      _savingplans = snapshot.docs.map((doc) => Savingplan.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to saving plans: $error");
    });
  }

  Future<void> addSavingPlan(String name, double target, double filling, SavingRangeType rangeType) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newPlan = Savingplan(
      id: '', // Firestore will generate ID
      name: name,
      target: target,
      filling: filling,
      rangeType: rangeType,
    );

    try {
      await _firestore.collection('users').doc(user.uid).collection('saving_plans').add(newPlan.toMap());
    } catch (e) {
      debugPrint("Error adding saving plan: $e");
      rethrow;
    }
  }

  Future<void> deleteSavingPlan(String planId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('saving_plans').doc(planId).delete();
    } catch (e) {
      debugPrint("Error deleting saving plan: $e");
      rethrow;
    }
  }

  Future<void> addFilling(String planId, double amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newTransaction = SavingTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: DateTime.now(),
    );

    try {
      final planRef = _firestore.collection('users').doc(user.uid).collection('saving_plans').doc(planId);
      await planRef.update({
        'transactions': FieldValue.arrayUnion([newTransaction.toMap()])
      });
    } catch (e) {
      debugPrint("Error adding filling: $e");
      rethrow;
    }
  }

  Future<void> editSavingTransaction(String planId, String transactionId, double newAmount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final planRef = _firestore.collection('users').doc(user.uid).collection('saving_plans').doc(planId);
    
    try {
      final doc = await planRef.get();
      if (!doc.exists) return;

      final plan = Savingplan.fromMap(doc.data()!, doc.id);
      final txIndex = plan.transactions.indexWhere((tx) => tx.id == transactionId);
      
      if (txIndex != -1) {
        plan.transactions[txIndex] = plan.transactions[txIndex].copyWith(amount: newAmount);
        await planRef.update({'transactions': plan.transactions.map((tx) => tx.toMap()).toList()});
      }
    } catch (e) {
      debugPrint("Error editing transaction: $e");
      rethrow;
    }
  }

  Future<void> deleteSavingTransaction(String planId, String transactionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final planRef = _firestore.collection('users').doc(user.uid).collection('saving_plans').doc(planId);

    try {
      final doc = await planRef.get();
      if (!doc.exists) return;

      final plan = Savingplan.fromMap(doc.data()!, doc.id);
      plan.transactions.removeWhere((tx) => tx.id == transactionId);
      
      await planRef.update({'transactions': plan.transactions.map((tx) => tx.toMap()).toList()});
    } catch (e) {
      debugPrint("Error deleting transaction: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _savingplanSubscription?.cancel();
    super.dispose();
  }
}
