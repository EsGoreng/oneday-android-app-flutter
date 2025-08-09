import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/widgets/common_widgets.dart'; // Sesuaikan path jika perlu
import './widgets/auth_widgets.dart'; // Sesuaikan path jika perlu

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  static const nameRoute = 'registerPage';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _registerWithEmailAndPassword() async {
    // Validasi form
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
      // 2. Buat user di Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        // 3. Buat dokumen user di Firestore
        String username = _emailController.text.split('@')[0]; // Username default dari email
        String defaultAvatar = 'https://api.dicebear.com/9.x/open-peeps/svg?seed=${username}';

        await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'username': username,
          'email': newUser.email,
          'createdAt': FieldValue.serverTimestamp(), // Simpan waktu server saat registrasi
          'profilePicturePath': defaultAvatar, // Foto profil default
        });
      }

        // Setelah berhasil, AuthWrapper akan mendeteksi dan mengarahkan ke home.
        // Namun, jika Anda ingin kembali ke halaman login, Anda bisa pop navigator.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Kembali ke halaman login
        }
      } on FirebaseAuthException catch (e) {
        // Tangani error spesifik dari Firebase
        String message;
        if (e.code == 'email-already-in-use') {
          message = 'This email is already registered.';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak.';
        } else {
          message = 'There is an error: ${e.message}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Tangani error umum lainnya
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const GridBackground(gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: AuthCard(
                    child: _buildRegisterForm(),
                  ),
                ),
              ),
            ),
          ),
          // Tombol kembali di pojok kiri atas
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create your account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Text(
            'Create your account below to register new account', style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text(
            'Email',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          CustomTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
              if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                return 'Masukkan alamat email yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Password',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          CustomTextField(
            controller: _passwordController,
            hintText: 'Enter your password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
              if (value.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Confiirm Password',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          CustomTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm your password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
              if (value != _passwordController.text) return 'Password tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Tombol Register
          SizedBox(
            width: double.infinity,
            height: 42,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Register',
                    onPressed: _registerWithEmailAndPassword,
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}