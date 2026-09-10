import 'package:app/screens/login_screen.dart';
import 'package:app/screens/uv_screen.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/uv_screen_skeleton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: UvScreenSkeleton());
        }

        if (snapshot.hasData) {
          return const UvIndexScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
