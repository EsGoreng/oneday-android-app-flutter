import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_models.dart';

class MoodProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Mood> _moods = [];
  StreamSubscription<QuerySnapshot>? _moodSubscription;

  List<Mood> get moods => _moods;

  MoodProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToMoods(user.uid);
      } else {
        _moodSubscription?.cancel();
        _moods = [];
        notifyListeners();
      }
    });
  }

  void listenToMoods(String userId) {
    _moodSubscription?.cancel();
    _moodSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .snapshots()
        .listen((snapshot) {
      _moods = snapshot.docs.map((doc) => Mood.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to moods: $error");
    });
  }

  // Fungsi getter ini akan tetap bekerja karena beroperasi pada list `_moods`
  List<Mood> getMoodsInDateRange(DateTime start, DateTime end) {
    return _moods.where((mood) {
      final moodDate = DateTime(mood.date.year, mood.date.month, mood.date.day);
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      return !moodDate.isBefore(startDate) && !moodDate.isAfter(endDate);
    }).toList();
  }

  Mood? getMoodForDay(DateTime day) {
    try {
      return _moods.firstWhere(
        (mood) =>
            mood.date.year == day.year &&
            mood.date.month == day.month &&
            mood.date.day == day.day,
      );
    } catch (e) {
      return null;
    }
  }

  // Fungsi untuk menyimpan (menambah atau memperbarui) mood di Firestore
  Future<void> saveMood(MoodCategory category, DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final collectionRef = _firestore.collection('users').doc(user.uid).collection('moods');
    
    // Normalisasi tanggal untuk memastikan query bekerja dengan benar (mengabaikan jam/menit)
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Cek apakah sudah ada mood untuk hari ini
    final querySnapshot = await collectionRef
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .limit(1)
        .get();

    final newMood = Mood(
      id: '', // ID akan di-generate oleh Firestore jika baru
      moodCategory: category,
      date: date,
    );

    try {
      if (querySnapshot.docs.isNotEmpty) {
        // Jika ada, update dokumen yang sudah ada
        final docId = querySnapshot.docs.first.id;
        await collectionRef.doc(docId).update(newMood.toMap());
      } else {
        // Jika tidak ada, tambahkan sebagai dokumen baru
        await collectionRef.add(newMood.toMap());
      }
    } catch (e) {
      debugPrint("Error saving mood: $e");
      rethrow;
    }
  }

  // Fungsi untuk menghapus mood dari Firestore
  Future<void> deleteMood(String moodId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('moods').doc(moodId).delete();
    } catch (e) {
      debugPrint("Error deleting mood: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _moodSubscription?.cancel();
    super.dispose();
  }
}
