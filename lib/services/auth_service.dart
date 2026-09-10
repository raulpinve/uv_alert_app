import 'package:app/config/api_config.dart';
import 'package:app/services/device_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      await sincronizarUsuario();

      return userCredential;
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

    await sincronizarUsuario();

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

    await sincronizarUsuario();

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

  Future<void> sincronizarUsuario() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/usuarios'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al sincronizar usuario '
        '(status ${response.statusCode}): ${response.body}',
      );
    }
  }
}
