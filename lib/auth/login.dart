import 'package:flutter/material.dart';
import 'package:oneday/auth/signup.dart';
import '../shared/widgets/common_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import './widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const nameRoute = 'loginPage';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Key untuk Form
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk email dan password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State untuk loading
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Fungsi untuk login dengan email dan password
  void _loginWithEmailAndPassword() async {
    // Validasi form terlebih dahulu
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Tampilkan loading indicator
      });
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Navigasi akan ditangani oleh AuthWrapper, tidak perlu navigasi manual.
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message ?? "Terjadi kesalahan"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
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
            _isLoading = false; // Sembunyikan loading indicator
          });
        }
      }
    }
  }

  void _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Pengguna membatalkan login
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // AuthWrapper akan menangani navigasi setelah state auth berubah
      await FirebaseAuth.instance.signInWithCredential(credential);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error : $e'),
              backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link has been sent to your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'An error occurred, please try again.';
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: CustomTextField(
          controller: emailController,
          hintText: 'Enter your registered email',
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Send Link',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                _sendPasswordResetEmail(email);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your email.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
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
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form( // Bungkus dengan widget Form
      key: _formKey, // Gunakan GlobalKey untuk form
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Login to your account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Text(
            'Enter your email below to login to your account', style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text(
            'Email',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email can\'t be empty';
              }
              if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                return 'Input valid Email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => _showForgotPasswordDialog(),
                child: const Text('Forgot Password?'),
            ),
            ],
          ),
          CustomTextField(
            controller: _passwordController,
            hintText: 'Enter your password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password can\'t be empty';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          // Tombol Login dengan Email & Password
          SizedBox(
            width: double.infinity,
            height: 42,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Login',
                    onPressed: _loginWithEmailAndPassword,
                  ),
          ),
          
          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.grey)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey)),
              ],
            ),
          ),
          
          // Tombol Login dengan Google
          SizedBox(
            width: double.infinity,
            height: 42,
            child: PrimaryButton(
              text: 'Login with Google',
              onPressed: _loginWithGoogle,
              color: Colors.white,
              textColor: Colors.black,
              icon: Image.asset(
                'images/icon/google_icon.png',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account?"),
              TextButton(
                onPressed: () {
                  // Navigasi ke halaman registrasi
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text(
                  'Register here',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}