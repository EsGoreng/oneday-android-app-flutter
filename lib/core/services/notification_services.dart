import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'task_channel_id';
  static const String _channelName = 'Task Notifications';
  static const String _channelDescription = 'Channel for task reminder notifications';

  Future<void> init() async {
    debugPrint("NotificationService: Initializing...");
    tz.initializeTimeZones();

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification')
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher_monochrome');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    debugPrint("NotificationService: Initialization complete.");
  }

  int _createUniqueId(String taskId, Duration reminderOffset) {
    return (taskId.hashCode + reminderOffset.inSeconds).hashCode;
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// -------------------------------------------------------------------
  /// FUNGSI BARU UNTUK NOTIFIKASI HARIAN ACAK (2-3 KALI SEHARI)
  /// -------------------------------------------------------------------
  Future<void> scheduleDailyEngagementNotification() async {
    const int baseNotificationId = 900; // ID dasar untuk notifikasi harian
    const List<Map<String, String>> messages = [
      // General & Productivity
      {'title': '☀️ A Fresh Start!', 'body': 'Your daily dashboard is ready. See what you can achieve today.'},
      {'title': '🎯 Ready to Go?', 'body': 'Your goals are waiting. Let\'s take the first step together!'},
      {'title': '📝 A Little Planning Goes a Long Way', 'body': 'Check in on your tasks and make today count.'},
      {'title': '🚀 Let\'s Make It Happen!', 'body': 'What\'s the one thing you want to accomplish today?'},

      // Finance Management
      {'title': '💰 Financial Check-in', 'body': 'How\'s your budget looking? A quick peek can bring peace of mind.'},
      {'title': '💸 Track Your Spending', 'body': 'Knowledge is power. See where your money went this week.'},
      {'title': '🏦 Your Savings Goal Awaits', 'body': 'Every penny saved is a step closer. Check your progress!'},
      {'title': '📊 Stay on Top of Your Finances', 'body': 'A moment to review your finances can secure your future.'},

      // Mood Tracking
      {'title': '😊 How Are You, Really?', 'body': 'Take a quiet moment for a quick mood check-in. It matters.'},
      {'title': '❤️ A Moment for Yourself', 'body': 'Checking in with your feelings is a form of self-care.'},
      {'title': '😌 Find Your Balance', 'body': 'Your emotional well-being is key. How are you feeling right now?'},
      {'title': '✨ Your Feelings Are Valid', 'body': 'Let\'s take a moment to acknowledge how you feel today.'},

      // Holistic / Combination
      {'title': '- Your Day at a Glance -', 'body': 'Tasks, finances, and feelings... it\'s all connected. See your full picture.'},
      {'title': '⚖️ Achieve Your Daily Balance', 'body': 'Ready to align your tasks, budget, and mood? Let\'s take a look.'},
      {'title': '⭐ The Complete You', 'body': 'From your to-dos to your mood, get a complete overview of your day.'},
    ];

    final random = Random();
    // Tentukan jumlah notifikasi secara acak: 2 atau 3
    final int notificationCount = 2 + random.nextInt(2); // Hasilnya akan 2 atau 3

    // Batalkan semua notifikasi harian sebelumnya untuk menghindari penumpukan
    for (int i = 0; i < 4; i++) { // Batalkan beberapa ID cadangan
      await flutterLocalNotificationsPlugin.cancel(baseNotificationId + i);
    }

    // Definisikan slot waktu untuk menyebar notifikasi
    List<Map<String, int>> timeSlots = [
      {'start': 9, 'end': 12},  // Pagi (09:00 - 11:59)
      {'start': 13, 'end': 17}, // Siang (13:00 - 16:59)
      {'start': 18, 'end': 21}, // Malam (18:00 - 20:59)
    ];
    timeSlots.shuffle(); // Acak urutan slot waktu

    for (int i = 0; i < notificationCount; i++) {
      final slot = timeSlots[i];
      final randomHour = slot['start']! + random.nextInt(slot['end']! - slot['start']!);
      final randomMinute = random.nextInt(60);

      // Dapatkan instance waktu valid berikutnya
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(randomHour, randomMinute);

      // Pilih pesan acak
      final randomMessage = messages[random.nextInt(messages.length)];
      final notificationId = baseNotificationId + i; // Buat ID unik untuk setiap notifikasi

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        randomMessage['title'],
        randomMessage['body'],
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher_monochrome',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher_monochrome'),
            sound: RawResourceAndroidNotificationSound('notification'),
          ),
          iOS: DarwinNotificationDetails(sound: 'task_reminder.caf'),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // PENTING: Jangan gunakan matchDateTimeComponents agar notifikasi tidak berulang
      );

      debugPrint("Notifikasi harian #${i+1} (ID: $notificationId) dijadwalkan pada: $scheduledDate");
    }
  }

  // Fungsi bantuan untuk mendapatkan instance waktu valid berikutnya
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Jika waktu yang dijadwalkan hari ini sudah lewat, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }


  /// -------------------------------------------------------------------
  /// FUNGSI UNTUK NOTIFIKASI TUGAS (TETAP SAMA)
  /// -------------------------------------------------------------------

  Future<void> scheduleNotification({
    required String taskId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required Duration reminderOffset,
  }) async {
    debugPrint("Scheduling notification for task $taskId at $scheduledTime (Offset: ${reminderOffset.inMinutes} mins)");

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _createUniqueId(taskId, reminderOffset),
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher_monochrome',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher_monochrome'),
          sound: RawResourceAndroidNotificationSound('task_reminder'),
        ),
        iOS: DarwinNotificationDetails(
          sound: 'task_reminder.caf',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint("Notification scheduled successfully for $taskId with offset ${reminderOffset.inMinutes} mins.");
  }

  Future<void> cancelScheduledNotifications(String taskId, List<Duration> reminderOffsets) async {
    debugPrint("Cancelling ${reminderOffsets.length} notifications for task $taskId");
    for (final offset in reminderOffsets) {
      final notificationId = _createUniqueId(taskId, offset);
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint("Cancelled notification for task $taskId with offset ${offset.inMinutes} mins (ID: $notificationId)");
    }
  }
}