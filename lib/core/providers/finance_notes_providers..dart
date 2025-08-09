import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/finance_notes_model.dart';

class FinanceNotesProviders with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Notes> _notes = [];
  StreamSubscription<QuerySnapshot>? _notesSubscription;

  List<Notes> get notes {
    // Urutkan catatan dari yang terbaru
    _notes.sort((a, b) => b.noteDate.compareTo(a.noteDate));
    return _notes;
  }

  FinanceNotesProviders() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToNotes(user.uid);
      } else {
        _notesSubscription?.cancel();
        _notes = [];
        notifyListeners();
      }
    });
  }

  void listenToNotes(String userId) {
    _notesSubscription?.cancel();
    _notesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notes') // Koleksi baru untuk notes
        .snapshots()
        .listen((snapshot) {
      _notes = snapshot.docs.map((doc) => Notes.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to notes: $error");
    });
  }

  Future<void> addNote(String name, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newNote = Notes(
      id: '', // Firestore akan generate ID
      noteName: name,
      noteDate: DateTime.now(),
      note: content,
    );

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .add(newNote.toMap());
    } catch (e) {
      debugPrint("Error adding note: $e");
      rethrow;
    }
  }

  Future<void> updateNote(String id, String newName, String newContent) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Kita hanya perlu memperbarui field yang berubah
    final Map<String, dynamic> updatedData = {
      'noteName': newName,
      'note': newContent,
      // noteDate tidak diupdate
    };

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .update(updatedData);
    } catch (e) {
      debugPrint("Error updating note: $e");
      rethrow;
    }
  }

  Future<void> deleteNote(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint("Error deleting note: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
