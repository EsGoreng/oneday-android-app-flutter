import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/timer_session_model.dart';

class TimerProvider with ChangeNotifier {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TimerSession> _completedSessions = [];
  StreamSubscription<QuerySnapshot>? _sessionSubscription;
  List<TimerSession> get completedSessions => _completedSessions;

  Duration _initialDuration = Duration.zero;
  Duration _remainingTime = Duration.zero;
  String _timerName = '';
  bool _isRunning = false;
  bool _isPaused = false;

  Duration get remainingTime => _remainingTime;
  String get timerName => _timerName;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;

  TimerProvider() {
    // Listener untuk background service (TETAP SAMA)
    _service.on('update').listen((data) {
      if (data != null) {
        _remainingTime = Duration(seconds: data['remaining_seconds'] ?? 0);
        _isRunning = data['is_running'] ?? false;
        _isPaused = data['is_paused'] ?? false;

        if (data.containsKey('timer_name')) {
          _timerName = data['timer_name'];
        }
        
        // Logika saat timer selesai secara alami
        if (!_isRunning && !_isPaused && _remainingTime.inSeconds == 0) {
          if (_timerName.isNotEmpty && _initialDuration.inSeconds > 0) {
            _addCompletedSession(_timerName, _initialDuration);
            _initialDuration = Duration.zero;
          }
          _timerName = '';
        }
        notifyListeners();
      }
    });

    // Listener BARU untuk data history dari Firestore
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToSessions(user.uid);
      } else {
        _sessionSubscription?.cancel();
        _completedSessions = [];
        notifyListeners();
      }
    });
  }

  void listenToSessions(String userId) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('timer_sessions') // Koleksi untuk riwayat sesi
        .orderBy('completedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _completedSessions = snapshot.docs.map((doc) => TimerSession.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to timer sessions: $error");
    });
  }

  // Fungsi BARU untuk menambah sesi ke Firestore
  Future<void> _addCompletedSession(String name, Duration duration) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final session = TimerSession(
      id: '', // Firestore akan generate ID
      name: name,
      actualDuration: duration,
      completedAt: DateTime.now(),
    );
    try {
      await _firestore.collection('users').doc(user.uid).collection('timer_sessions').add(session.toMap());
    } catch (e) {
      debugPrint("Error adding completed session: $e");
    }
  }

  // Fungsi hapus sesi DIPERBARUI untuk Firestore
  Future<void> deleteSessions(List<String> sessionIdsToDelete) async {
    final user = _auth.currentUser;
    if (user == null || sessionIdsToDelete.isEmpty) return;

    final batch = _firestore.batch();
    final collectionRef = _firestore.collection('users').doc(user.uid).collection('timer_sessions');
    for (final id in sessionIdsToDelete) {
      batch.delete(collectionRef.doc(id));
    }
    try {
      await batch.commit();
    } catch (e) {
      debugPrint("Error deleting sessions: $e");
      rethrow;
    }
  }

  Future<void> _ensureServiceIsRunning() async {
    final isServiceRunning = await _service.isRunning();
    if (!isServiceRunning) {
      await _service.startService();
    }
  }

  Future<void> startTimer(String name, Duration duration) async {
    if (_isRunning || _isPaused) {
      await stopTimer();
    }
    await _ensureServiceIsRunning();
    _service.invoke('startOrResumeTimer', {
      'timer_name': name,
      'duration_seconds': duration.inSeconds,
    });

    _initialDuration = duration;
    _timerName = name;
    _isRunning = true;
    _isPaused = false;
    _remainingTime = duration;
    notifyListeners();
  }

  Future<void> pauseTimer() async {
    if (_isRunning) {
      await _ensureServiceIsRunning();
      _service.invoke('pauseTimer');
      _isRunning = false;
      _isPaused = true;
      notifyListeners();
    }
  }

  Future<void> resumeTimer() async {
    if (_isPaused && _remainingTime.inSeconds > 0) {
      await _ensureServiceIsRunning();
      _service.invoke('startOrResumeTimer', {
        'timer_name': _timerName,
        'duration_seconds': _remainingTime.inSeconds,
      });
      _isRunning = true;
      _isPaused = false;
      notifyListeners();
    }
  }

  // Fungsi stopTimer DIPERBARUI untuk menyimpan sesi ke Firestore
  Future<void> stopTimer() async {
    if (_timerName.isNotEmpty) {
      final actualDuration = _initialDuration - _remainingTime;
      if (actualDuration.inSeconds > 5) { // Hanya catat jika berjalan > 5 detik
        await _addCompletedSession(_timerName, actualDuration);
      }
    }
    await _ensureServiceIsRunning();
    _service.invoke('stopService');
    
    _remainingTime = Duration.zero;
    _isRunning = false;
    _isPaused = false;
    _timerName = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
