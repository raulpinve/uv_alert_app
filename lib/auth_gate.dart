import 'package:app/screens/login_screen.dart';
import 'package:app/screens/uv_screen.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/uv_screen_skeleton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();

  String? _uidEnProceso;
  Future<void>? _deviceRegistrationFuture;

  Future<void> _ensureDeviceRegistered(String uid) {
    if (_uidEnProceso != uid) {
      _uidEnProceso = uid;
      _deviceRegistrationFuture = _authService.registrarDispositivoActual();
    }
    return _deviceRegistrationFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: UvScreenSkeleton());
        }

        final user = snapshot.data;

        if (user == null) {
          _uidEnProceso = null;
          return const LoginScreen();
        }

        return FutureBuilder<void>(
          future: _ensureDeviceRegistered(user.uid),
          builder: (context, deviceSnapshot) {
            if (deviceSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(body: UvScreenSkeleton());
            }
            return const UvScreen();
          },
        );
      },
    );
  }
}
