import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_notes_model.dart';

class HabitNotesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<HabitNote> _notes = [];
  StreamSubscription<QuerySnapshot>? _notesSubscription;

  List<HabitNote> get notes {
    _notes.sort((a, b) => b.noteDate.compareTo(a.noteDate));
    return _notes;
  }

  HabitNotesProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToHabitNotes(user.uid);
      } else {
        _notesSubscription?.cancel();
        _notes = [];
        notifyListeners();
      }
    });
  }

  void listenToHabitNotes(String userId) {
    _notesSubscription?.cancel();
    _notesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('habit_notes') // Koleksi baru untuk habit notes
        .snapshots()
        .listen((snapshot) {
      _notes = snapshot.docs.map((doc) => HabitNote.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to habit notes: $error");
    });
  }

  Future<void> addNote(String name, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newNote = HabitNote(
      id: '', // Firestore will generate ID
      noteName: name,
      noteDate: DateTime.now(),
      note: content,
    );

    try {
      await _firestore.collection('users').doc(user.uid).collection('habit_notes').add(newNote.toMap());
    } catch (e) {
      debugPrint("Error adding habit note: $e");
      rethrow;
    }
  }

  Future<void> updateNote(String id, String newName, String newContent) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updatedData = {
      'noteName': newName,
      'note': newContent,
    };

    try {
      await _firestore.collection('users').doc(user.uid).collection('habit_notes').doc(id).update(updatedData);
    } catch (e) {
      debugPrint("Error updating habit note: $e");
      rethrow;
    }
  }

  Future<void> deleteNote(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('habit_notes').doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting habit note: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
