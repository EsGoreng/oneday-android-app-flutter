import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oneday/core/services/notification_services.dart';
import '../models/task_model.dart';
import 'package:oneday/core/services/home_widget_service.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  List<Task> _tasks = [];
  StreamSubscription<QuerySnapshot>? _taskSubscription;

  List<Task> get tasks => _tasks;

  TaskProvider() {  
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToTasks(user.uid);
      } else {
        _taskSubscription?.cancel();
        _tasks = [];
        notifyListeners();
      }
    });
  }

  void listenToTasks(String userId) {
    _taskSubscription?.cancel();
    _taskSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .listen((snapshot) {
      _tasks = snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
      sendTasksToWidget();
    }, onError: (error) {
      debugPrint("Error listening to tasks: $error");
    });
  }

  List<Task> getTasksForDay(DateTime day) {
    return _tasks.where((task) {
      return _normalizeDate(task.date) == _normalizeDate(day);
    }).toList();
  }

  DateTime _normalizeDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Future<void> addTask(
    String title,
    String description,
    DateTime date,
    TaskPriority priority,
    List<Duration> reminderOffsets,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final offsetsInMinutes = reminderOffsets.map((d) => d.inMinutes).toList();

    final newTask = Task(
      id: '', title: title, description: description, date: date,
      priority: priority, status: false,
      reminderOffsets: offsetsInMinutes,
    );
    try {
      final docRef = await _firestore.collection('users').doc(user.uid).collection('tasks').add(newTask.toMap());
      
      // --- PERUBAHAN DI SINI ---
      final now = DateTime.now();
      for (final offset in reminderOffsets) {
        final scheduledTime = date.subtract(offset);
        // Hanya jadwalkan notifikasi jika waktunya di masa depan
        if (scheduledTime.isAfter(now)) {
          await _notificationService.scheduleNotification(
            taskId: docRef.id,
            title: 'Upcoming Task: $title',
            body: description.isNotEmpty ? description : 'Don\'t forget to complete your task!',
            scheduledTime: scheduledTime,
            reminderOffset: offset,
          );
        }
      }

    } catch (e) {
      debugPrint("Error adding task: $e");
      rethrow;
    }
    await sendTasksToWidget();
  }

  Future<void> updateTask(Task taskToUpdate, Task oldTask) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (oldTask.reminderOffsets != null) {
        final oldOffsets = oldTask.reminderOffsets!.map((m) => Duration(minutes: m)).toList();
        await _notificationService.cancelScheduledNotifications(oldTask.id, oldOffsets);
      }

      await _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskToUpdate.id).update(taskToUpdate.toMap());

      // --- PERUBAHAN DI SINI ---
      if (taskToUpdate.reminderOffsets != null) {
        final newOffsets = taskToUpdate.reminderOffsets!.map((m) => Duration(minutes: m)).toList();
        final now = DateTime.now();
        for (final offset in newOffsets) {
          final scheduledTime = taskToUpdate.date.subtract(offset);
          // Hanya jadwalkan notifikasi jika waktunya di masa depan
          if (scheduledTime.isAfter(now)) {
            await _notificationService.scheduleNotification(
              taskId: taskToUpdate.id,
              title: 'Upcoming Task: ${taskToUpdate.title}',
              body: taskToUpdate.description.isNotEmpty ? taskToUpdate.description : 'Don\'t forget to complete your task!',
              scheduledTime: scheduledTime,
              reminderOffset: offset,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error updating task: $e");
      rethrow;
    }
    await sendTasksToWidget();
  }

  Future<void> addRecurringTasks({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required TaskPriority priority,
    required Set<int> daysOfWeek,
    required List<Duration> reminderOffsets,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final offsetsInMinutes = reminderOffsets.map((d) => d.inMinutes).toList();
    final groupId = 'recur_${DateTime.now().millisecondsSinceEpoch}';
    final collectionRef = _firestore.collection('users').doc(user.uid).collection('tasks');
    final batch = _firestore.batch();
    final now = DateTime.now(); // Ambil waktu saat ini

    for (var day = startDate; day.isBefore(endDate.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
      if (daysOfWeek.contains(day.weekday)) {
        final taskDateTimeForThisIteration = DateTime(
          day.year, day.month, day.day,
          startDate.hour, startDate.minute,
        );
        
        final docRef = collectionRef.doc();
        final newTask = Task(
          id: docRef.id, recurringGroupId: groupId, title: title,
          description: description, date: taskDateTimeForThisIteration,
          priority: priority, status: false, reminderOffsets: offsetsInMinutes,
        );
        batch.set(docRef, newTask.toMap());

        // --- PERUBAHAN DI SINI ---
        for (final offset in reminderOffsets) {
          final scheduledTime = taskDateTimeForThisIteration.subtract(offset);
          // Hanya jadwalkan notifikasi jika waktunya di masa depan
          if (scheduledTime.isAfter(now)) {
            await _notificationService.scheduleNotification(
              taskId: docRef.id,
              title: 'Task : $title',
              body: description.isNotEmpty ? description : 'Don\'t forget to complete your task!',
              scheduledTime: scheduledTime,
              reminderOffset: offset,
            );
          }
        }
      }
    }
    try {
      await batch.commit();
    } catch (e) {
      debugPrint("Error adding recurring tasks: $e");
      rethrow;
    }
    await sendTasksToWidget();
  }

  // ... (sisa fungsi deleteTask, deleteTaskSeries, toggleTaskStatus, dan dispose tetap sama)
  Future<void> deleteTask(String taskId) async {
  final user = _auth.currentUser;
  if (user == null) return;
  
  final docRef = _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId);

  try {
    // AMBIL DATA DULU SEBELUM DIHAPUS
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final taskData = Task.fromMap(docSnapshot.data()!, docSnapshot.id);
      
      // Hapus dokumen dari Firestore
      await docRef.delete();

      // BATALKAN NOTIFIKASI menggunakan data yang sudah diambil
      if (taskData.reminderOffsets != null) {
        final offsets = taskData.reminderOffsets!.map((m) => Duration(minutes: m)).toList();
        await _notificationService.cancelScheduledNotifications(taskId, offsets);
      }
    }
  } catch (e) {
    debugPrint("Error deleting task: $e");
    rethrow;
  }
  await sendTasksToWidget();
}

  Future<void> deleteTaskSeries(String groupId) async {
  final user = _auth.currentUser;
  if (user == null) return;

  final collectionRef = _firestore.collection('users').doc(user.uid).collection('tasks');
  final querySnapshot = await collectionRef.where('recurringGroupId', isEqualTo: groupId).get();
  
  final batch = _firestore.batch();
  try {
    for (var doc in querySnapshot.docs) {
      // Hapus dokumen dari batch
      batch.delete(doc.reference);
      
      // BATALKAN NOTIFIKASI
      final taskData = Task.fromMap(doc.data(), doc.id);
      if (taskData.reminderOffsets != null) {
        final offsets = taskData.reminderOffsets!.map((m) => Duration(minutes: m)).toList();
        // Panggil service untuk setiap task dalam series
        await _notificationService.cancelScheduledNotifications(doc.id, offsets);
      }
    }
    await batch.commit();
  } catch (e) {
    debugPrint("Error deleting task series: $e");
    rethrow;
  }
  await sendTasksToWidget();
}

  Future<void> toggleTaskStatus(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId);
    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final currentStatus = doc.data()?['status'] ?? false;
        await docRef.update({'status': !currentStatus});
      }
    } catch (e) {
      debugPrint('Error toggling task status: $e');
      rethrow;
    }
    await sendTasksToWidget();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }
}