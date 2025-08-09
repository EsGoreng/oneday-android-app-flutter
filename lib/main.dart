import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oneday/core/services/notification_services.dart';
import 'package:oneday/features/home/pages/profile_page.dart';
import 'package:oneday/shared/widgets/mainnavigation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'auth/login.dart';
import 'auth/profile.dart';
import 'auth/signup.dart';
import 'core/providers/budget_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/finance_notes_providers..dart';
import 'core/providers/habit_notes_provider.dart';
import 'core/providers/mood_notes_provider.dart';
import 'core/providers/mood_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/savingplan_provider.dart';
import 'core/providers/task_provider.dart';
import 'core/providers/timer_preset_provider.dart';
import 'core/providers/timer_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/services/background_services.dart';
import 'features/finance/pages/category_page.dart';
import 'features/finance/pages/transaction_page.dart';
import 'firebase_options.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}


Future<void> main() async {

  HttpOverrides.global = MyHttpOverrides();

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    MobileAds.instance.initialize();

    await initializeDateFormatting('id_ID', null);

    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
    // Inisialisasi Notification Service
    await NotificationService().init();
    
   // Minta izin notifikasi
    await NotificationService().requestPermissions();

    // Minta izin notifikasi biasa
    await Permission.notification.request();

    await _checkAndRequestExactAlarmPermission(); 

    await NotificationService().scheduleDailyEngagementNotification();

    await initializeService();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ProfileProvider()),
          ChangeNotifierProvider(create: (context) => SavingplanProvider()),
          ChangeNotifierProvider(create: (context) => HabitNotesProvider()),
          ChangeNotifierProvider(create: (context) => FinanceNotesProviders()),
          ChangeNotifierProxyProvider<ProfileProvider, TransactionProvider>(
            create: (context) => TransactionProvider(),
            update: (context, profileProvider, previousTransactionProvider) {
              previousTransactionProvider?.updateProfileProvider(profileProvider);
              return previousTransactionProvider!;
            },
          ),
          ChangeNotifierProxyProvider<TransactionProvider, BudgetProvider>(
            create: (context) => BudgetProvider(null),
            update: (context, transactionProvider, previousBudgetProvider) {
              return previousBudgetProvider!..updateDependencies(transactionProvider);
            },
          ),
          ChangeNotifierProvider(create: (context) => TaskProvider()),
          ChangeNotifierProvider(create: (context) => CategoryProvider()),
          ChangeNotifierProvider(create: (context) => TimerProvider()),
          ChangeNotifierProvider(create: (context) => TimerPresetProvider()),
          ChangeNotifierProvider(create: (context) => MoodProvider()),
          ChangeNotifierProvider(create: (context) => MoodNotesProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('FATAL ERROR - APP CRASHED: $e');
    debugPrint('STACK TRACE: $stackTrace');
  }
}

Future<void> _checkAndRequestExactAlarmPermission() async {
  final status = await Permission.scheduleExactAlarm.status;
  print('Exact Alarm permission status: $status'); // Untuk debugging
  if (status.isDenied) {
    final result = await Permission.scheduleExactAlarm.request();
    print('Exact Alarm permission request result: $result'); // Untuk debugging
    if (result.isPermanentlyDenied) {
      // Opsional: Tampilkan dialog yang memberi tahu pengguna untuk mengaktifkannya di pengaturan
      // await openAppSettings();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const AuthWrapper(),
      routes: {
        LoginPage.nameRoute: (context) => const LoginPage(),
        RegisterPage.nameRoute: (context) => const RegisterPage(),
        HistoryPage.nameRoute: (context) => const HistoryPage(),
        CategoryPage.nameRoute: (context) => const CategoryPage(),
        MainNavigationWrapper.nameRoute: (context) => const MainNavigationWrapper(),
        ProfileLoginPage.nameRoute: (context) => const ProfileLoginPage(),
        ProfilePage.nameRoute: (context) => const ProfilePage(),
      },
    );
  }
}

// UBAH: AuthWrapper menjadi StatefulWidget untuk kontrol penuh
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final StreamSubscription<User?> _authSubscription;
  User? _user;

  @override
  void initState() {
    super.initState();
    // Langsung mendengarkan perubahan status otentikasi
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) { // Pastikan widget masih ada di tree
        setState(() {
          _user = user;
        });
        
        if (user != null) {
          // Saat user login, simpan UID-nya untuk diakses widget
          HomeWidget.saveWidgetData<String>('user_id', user.uid);
          debugPrint("User ID ${user.uid} saved for widget.");
        } else {
          // Saat user logout, hapus UID-nya
          HomeWidget.saveWidgetData<String>('user_id', null);
          debugPrint("User ID cleared for widget.");
        }
        
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // Batalkan listener untuk mencegah memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logika tunggal untuk menentukan halaman
    if (_user == null) {
      return const LoginPage();
    } else {
      return const ProfileChecker();
    }
  }
}

// Widget ini bertugas memeriksa apakah profil pengguna sudah ada
class ProfileChecker extends StatelessWidget {
  const ProfileChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // Selama provider sedang memuat data, tampilkan loading
        if (profileProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Arahkan berdasarkan keberadaan profil
        if (profileProvider.profileExists) {
          return const MainNavigationWrapper();
        } else {
          return const ProfileLoginPage();
        }
      },
    );
  }
}
