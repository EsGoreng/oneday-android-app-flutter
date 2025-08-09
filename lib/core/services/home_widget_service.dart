import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:oneday/core/services/auth_services.dart';
import 'package:oneday/firebase_options.dart';
import '../models/task_model.dart';

Future<void> sendTasksToWidget() async {
   try {
     // Pastikan Firebase sudah diinisialisasi
     if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
     }
     
     final userId = await AuthService().getCurrentUserId();
     if (userId == null) return;

     final firestore = FirebaseFirestore.instance;
     final now = DateTime.now();
     final startOfDay = DateTime(now.year, now.month, now.day);
     final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

     final snapshot = await firestore
         .collection('users')
         .doc(userId)
         .collection('tasks')
         .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
         .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
         .get();

     final tasks = snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();

     // Konversi list Task ke JSON string
     final tasksJson = jsonEncode(
       tasks.map((task) => {
         'id': task.id,
         'title': task.title,
         'description': task.description,
         'status': task.status,
       }).toList(),
     );

     // Simpan data dan update widget
     await HomeWidget.saveWidgetData<String>('tasks_json', tasksJson);
     await HomeWidget.updateWidget(
       name: 'TaskWidgetProvider', // Nama kelas provider di sisi native
       androidName: 'TaskWidgetProvider',
     );
   } catch (e) {
     debugPrint("Error sending data to widget: $e");
   }
}
