import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _userName = '';
  String _currencyLocale = 'id_ID';
  String _currencySymbol = 'Rp';
  String _profilePicturePath = 'https://api.dicebear.com/9.x/open-peeps/svg?seed=Felix';
  int _age = 0; // DATA BARU
  String _jobStatus = ''; // DATA BARU


  // isLoading harus default ke true untuk menangani pengecekan awal
  bool _isLoading = true;
  bool _profileExists = false;

  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _currentUserId;

  String get userName => _userName;
  String get currencyLocale => _currencyLocale;
  String get currencySymbol => _currencySymbol;
  String get profilePicturePath => _profilePicturePath;
  int get age => _age; // GETTER BARU
  String get jobStatus => _jobStatus; // GETTER BARU
  bool get isLoading => _isLoading;
  bool get profileExists => _profileExists;

  // Constructor akan secara otomatis mendengarkan perubahan status otentikasi
  ProfileProvider() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        // Jika user login (atau sudah login saat aplikasi dibuka)
        // dan user ID-nya berbeda dari yang terakhir didengarkan.
        if (user.uid != _currentUserId) {
          listenToProfile(user.uid);
        }
      } else {
        // Jika user logout, reset semua state ke kondisi awal.
        _resetState();
      }
    });
  }

  // Fungsi untuk mereset state provider ke nilai default
  void _resetState() {
    _userName = '';
    _currencyLocale = 'id_ID';
    _currencySymbol = 'Rp';
    _profilePicturePath = 'https://api.dicebear.com/9.x/open-peeps/svg?seed=Felix';
    _age = 0; // RESET DATA BARU
    _jobStatus = ''; // RESET DATA BARU
    _isLoading = true; // Penting: set ke true agar loading muncul saat login ulang
    _profileExists = false;
    _currentUserId = null;
    _profileSubscription?.cancel(); // Batalkan listener profil yang lama
    notifyListeners(); // Beri tahu UI tentang perubahan ini
  }

  void listenToProfile(String userId) {
    _currentUserId = userId;
    _profileSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _profileSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      _isLoading = false;
      if (snapshot.exists && snapshot.data() != null) {
        _profileExists = true;
        final data = snapshot.data()!;
        _userName = data['userName'] ?? '';
        _currencyLocale = data['currencyLocale'] ?? 'id_ID';
        _currencySymbol = data['currencySymbol'] ?? 'Rp';
        _profilePicturePath = data['profilePicturePath'] ?? 'https://api.dicebear.com/9.x/open-peeps/svg?seed=Felix';
        _age = data['age'] ?? 0; // AMBIL DATA BARU
        _jobStatus = data['jobStatus'] ?? ''; // AMBIL DATA BARU
      } else {
        _profileExists = false;
      }
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to profile: $error");
      _isLoading = false;
      _profileExists = false;
      notifyListeners();
    });
  }

  // FUNGSI BARU UNTUK MENYIMPAN DATA PROFIL AWAL
  Future<void> setInitialProfile({
    required String userName,
    required String currencyLocale,
    required String currencySymbol,
    required int age,
    required String jobStatus,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'userName': userName,
        'currencyLocale': currencyLocale,
        'currencySymbol': currencySymbol,
        'age': age,
        'jobStatus': jobStatus,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error setting initial profile: $e");
      rethrow;
    }
  }


  Future<void> setUserName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'userName': newName,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating username: $e");
      rethrow;
    }
  }

  Future<void> setCurrency(String newLocale, String newSymbol) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'currencyLocale': newLocale,
        'currencySymbol': newSymbol,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating currency: $e");
      rethrow;
    }
  }
  
  // FUNGSI BARU UNTUK MEMPERBARUI UMUR DAN STATUS PEKERJAAN
  Future<void> setAgeAndJobStatus(int newAge, String newJobStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'age': newAge,
        'jobStatus': newJobStatus,
      });
    } catch (e) {
      debugPrint("Error updating age and job status: $e");
      rethrow;
    }
  }

  Future<void> setProfilePicture(String newPath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({'profilePicturePath': newPath});
    } catch (e) {
      debugPrint("Error updating profile picture: $e");
      rethrow;
    }
  }

  // Pastikan untuk membatalkan semua listener saat provider di-dispose
  @override
  void dispose() {
    _profileSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}