import 'package:app/features/device/data/device_service.dart';
import 'package:app/features/auth/data/user_service.dart'; // nuevo import
import 'package:app/core/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Renombrado: ahora sincroniza usuario Y dispositivo, en ese orden.
  Future<void> sincronizarSesionActual() => _sincronizarUsuarioYDispositivo();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
      // El AuthGate se encarga de sincronizar usuario y dispositivo
    } on FirebaseAuthException catch (e) {
      debugPrint('Error de FirebaseAuth: ${e.message}');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return credential;
  }

  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // El AuthGate se encarga de sincronizar usuario y dispositivo
    // (se quita la llamada directa de acá para no duplicar el flujo)

    return credential;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    try {
      await DeviceService().desregistrarDispositivo();
    } catch (e) {
      debugPrint('Error al desregistrar dispositivo: $e');
    }

    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Sincroniza el usuario en el backend y, si tiene éxito, registra
  /// el dispositivo. No bloquea ni rompe el flujo de login si algo falla.
  Future<void> _sincronizarUsuarioYDispositivo() async {
    try {
      await UserService().sincronizarUsuario();
    } catch (e) {
      debugPrint('[${DateTime.now()}] ERROR sincronizando usuario: $e');
      // Si el usuario no se pudo sincronizar, el registro de dispositivo
      // fallará igual (depende de que el usuario ya exista), así que no
      // tiene sentido intentarlo.
      return;
    }

    try {
      final fcmToken = await NotificationService.instance.getToken();

      if (fcmToken == null) {
        debugPrint('No se pudo obtener el fcmToken, se omite registro.');
        return;
      }

      final position = await _obtenerUbicacion();

      await DeviceService().registrarDispositivo(
        fcmToken: fcmToken,
        latitud: position?.latitude ?? 0.0,
        longitud: position?.longitude ?? 0.0,
      );
    } catch (e) {
      debugPrint('[${DateTime.now()}] ERROR registro dispositivo: $e');
    }
  }

  Future<Position?> _obtenerUbicacion() async {
    try {
      final permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        final nuevoPermiso = await Geolocator.requestPermission();
        if (nuevoPermiso == LocationPermission.denied ||
            nuevoPermiso == LocationPermission.deniedForever) {
          return null;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
      return null;
    }
  }
}
