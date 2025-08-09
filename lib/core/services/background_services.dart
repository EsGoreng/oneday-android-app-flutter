import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  Timer? timer;
  DateTime? endTime;
  String currentTimerName = '';

  void resetNotificationToIdle() {
    flutterLocalNotificationsPlugin.show(
      888,
      'Focus Timer', // Judul awal
      'Service is ready to use.', // Konten awal
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'my_app_timer_channel',
          'Timer Channel',
          icon: '@mipmap/ic_launcher_monochrome',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher_monochrome'),
          ongoing: false,
          importance: Importance.low,
        ),
      ),
    );
  }

  resetNotificationToIdle();

  service.on('startOrResumeTimer').listen((data) {
    if (data == null) return;

    currentTimerName = data['timer_name'] as String;
    final durationInSeconds = data['duration_seconds'] as int;
    endTime = DateTime.now().add(Duration(seconds: durationInSeconds));

    timer?.cancel(); // Selalu batalkan timer lama sebelum memulai yang baru
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (endTime == null || now.isAfter(endTime!)) {
        timer.cancel();

        // Kirim update terakhir dan jangan matikan service.
        service.invoke('update', {
          'is_running': false,
          'is_paused': false,
          'remaining_seconds': 0,
          'timer_name': '' // Reset nama timer di provider
        });
        resetNotificationToIdle();
      } else {
        final remaining = endTime!.difference(now);
        service.invoke('update', {
          'is_running': true,
          'is_paused': false,
          'remaining_seconds': remaining.inSeconds,
          'timer_name': currentTimerName
        });

        // Update notifikasi
        flutterLocalNotificationsPlugin.show(
          888,
          currentTimerName,
          'Time Left: ${remaining.inSeconds.toHHMMSS()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_app_timer_channel',
              'Timer Channel',
              icon: '@mipmap/ic_launcher_monochrome',
              largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher_monochrome'),
              ongoing: false,
              importance: Importance.low,
            ),
          ),
        );
      }
    });
  });

  service.on('pauseTimer').listen((data) {
    timer?.cancel();
    if (endTime != null) {
      final remainingOnPause = endTime!.difference(DateTime.now());
      service.invoke('update', {
        'is_running': false,
        'is_paused': true,
        'remaining_seconds': remainingOnPause.isNegative ? 0 : remainingOnPause.inSeconds,
        'timer_name': currentTimerName
      });
      
      flutterLocalNotificationsPlugin.show(
        888,
        '$currentTimerName (Dijeda)',
        'Timer is Paused',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'my_app_timer_channel',
            'Timer Channel',
            icon: '@mipmap/ic_launcher_monochrome',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher_monochrome'),
            ongoing: false,
            importance: Importance.low,
          ),
        ),
      );
    }
  });

  service.on('stopService').listen((event) {
    timer?.cancel();
    endTime = null;
    currentTimerName = '';
    flutterLocalNotificationsPlugin.cancel(888);
    
    service.invoke('update', {
      'is_running': false,
      'is_paused': false,
      'remaining_seconds': 0,
      'timer_name': ''
    });
    resetNotificationToIdle();
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_app_timer_channel',
    'Timer Channel',
    description: 'Channel ini digunakan untuk notifikasi timer.',
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false, // Mulai service saat aplikasi pertama kali dijalankan
      notificationChannelId: 'my_app_timer_channel',
      initialNotificationTitle: 'Timer',
      initialNotificationContent: 'Service Ready.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

/// Extension untuk format waktu HH:MM:SS
extension on int {
  String toHHMMSS() {
    final hours = (this ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((this % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (this % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}