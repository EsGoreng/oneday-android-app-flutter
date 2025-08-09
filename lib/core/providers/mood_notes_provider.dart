import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_notes_model.dart';

class MoodNotesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<MoodNote> _notes = [];
  StreamSubscription<QuerySnapshot>? _notesSubscription;

  List<MoodNote> get notes {
    _notes.sort((a, b) => b.noteDate.compareTo(a.noteDate));
    return _notes;
  }

  MoodNotesProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToMoodNotes(user.uid);
      } else {
        _notesSubscription?.cancel();
        _notes = [];
        notifyListeners();
      }
    });
  }

  void listenToMoodNotes(String userId) {
    _notesSubscription?.cancel();
    _notesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_notes') // Koleksi baru untuk mood notes
        .snapshots()
        .listen((snapshot) {
      _notes = snapshot.docs.map((doc) => MoodNote.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to mood notes: $error");
    });
  }

  Future<void> addNote(String name, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newNote = MoodNote(
      id: '', // Firestore will generate ID
      noteName: name,
      noteDate: DateTime.now(),
      note: content,
    );

    try {
      await _firestore.collection('users').doc(user.uid).collection('mood_notes').add(newNote.toMap());
    } catch (e) {
      debugPrint("Error adding mood note: $e");
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
      await _firestore.collection('users').doc(user.uid).collection('mood_notes').doc(id).update(updatedData);
    } catch (e) {
      debugPrint("Error updating mood note: $e");
      rethrow;
    }
  }

  Future<void> deleteNote(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('mood_notes').doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting mood note: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
