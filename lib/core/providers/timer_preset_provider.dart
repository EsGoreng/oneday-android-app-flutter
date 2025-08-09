import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/timer_model.dart';

class TimerPresetProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TimerModel> _timers = [];
  StreamSubscription<QuerySnapshot>? _timerSubscription;

  List<TimerModel> get timers => _timers;

  TimerPresetProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToPresets(user.uid);
      } else {
        _timerSubscription?.cancel();
        _timers = [];
        notifyListeners();
      }
    });
  }

  void listenToPresets(String userId) {
    _timerSubscription?.cancel();
    _timerSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('timer_presets') // Koleksi untuk preset
        .snapshots()
        .listen((snapshot) {
      _timers = snapshot.docs.map((doc) => TimerModel.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to timer presets: $error");
    });
  }

  Future<void> addTimer(String name, int duration, String? description) async {
    final user = _auth.currentUser;
    if (user == null || duration <= 0) return;

    final newTimer = TimerModel(
      id: '', // Firestore akan generate ID
      name: name,
      description: description,
      duration: duration,
    );
    try {
      await _firestore.collection('users').doc(user.uid).collection('timer_presets').add(newTimer.toMap());
    } catch (e) {
      debugPrint("Error adding timer preset: $e");
      rethrow;
    }
  }

  Future<void> deleteMultipleTimers(List<String> timerIdsToDelete) async {
    final user = _auth.currentUser;
    if (user == null || timerIdsToDelete.isEmpty) return;

    final batch = _firestore.batch();
    final collectionRef = _firestore.collection('users').doc(user.uid).collection('timer_presets');

    for (final id in timerIdsToDelete) {
      batch.delete(collectionRef.doc(id));
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint("Error deleting multiple timer presets: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _timerSubscription?.cancel();
    super.dispose();
  }
}
