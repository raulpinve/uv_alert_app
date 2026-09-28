import 'package:app/features/auth/presentation/screens/login_screen.dart';
import 'package:app/features/uv/presentation/screens/uv_screen.dart';
import 'package:app/features/auth/data/auth_service.dart';
import 'package:app/core/widgets/uv_screen_skeleton.dart';
import 'package:app/core/widgets/uv_sync_error.dart';
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
      _deviceRegistrationFuture = _authService.sincronizarSesionActual();
    }
    return _deviceRegistrationFuture!;
  }

  void _reintentar(String uid) {
    setState(() {
      _uidEnProceso = null; // fuerza a _ensureDeviceRegistered a relanzar
    });
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
          builder: (context, syncSnapshot) {
            if (syncSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(body: UvScreenSkeleton());
            }

            if (syncSnapshot.hasError) {
              return Scaffold(
                body: UvSyncError(onRetry: () => _reintentar(user.uid)),
              );
            }

            return const UvScreen();
          },
        );
      },
    );
  }
}
