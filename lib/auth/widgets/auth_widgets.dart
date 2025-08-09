import 'package:flutter/material.dart';

/// Kartu dasar yang reusable untuk form autentikasi (Login/Sign Up).
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfffef3c8),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}