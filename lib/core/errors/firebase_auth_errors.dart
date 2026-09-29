import 'package:firebase_auth/firebase_auth.dart';

/// Traduce el `code` de un [FirebaseAuthException] a un mensaje legible
/// en español. Úsalo en cualquier catch de FirebaseAuth en vez de
/// mostrar `e.toString()` o `e.message` directo al usuario.
String mensajeFirebaseAuth(FirebaseAuthException e) {
  switch (e.code) {
    case 'network-request-failed':
      return 'No se pudo conectar. Verifica tu conexión a internet.';

    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      // Por seguridad, no distinguimos "no existe" de "contraseña
      // incorrecta" — evita que alguien confirme qué correos están
      // registrados probando contraseñas al azar.
      return 'Correo o contraseña incorrectos.';

    case 'invalid-email':
      return 'El correo ingresado no es válido.';

    case 'user-disabled':
      return 'Esta cuenta ha sido deshabilitada.';

    case 'email-already-in-use':
      return 'Ya existe una cuenta con este correo.';

    case 'weak-password':
      return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';

    case 'too-many-requests':
      return 'Demasiados intentos. Espera un momento antes de volver a intentar.';

    case 'operation-not-allowed':
      return 'Este método de inicio de sesión no está habilitado.';

    case 'account-exists-with-different-credential':
      return 'Ya existe una cuenta con este correo usando otro método de inicio de sesión.';

    case 'requires-recent-login':
      return 'Por seguridad, vuelve a iniciar sesión para continuar.';

    case 'popup-closed-by-user':
    case 'sign_in_canceled': // google_sign_in en algunas plataformas
      return 'Inicio de sesión cancelado.';

    default:
      return 'Ocurrió un error al iniciar sesión. Intenta de nuevo.';
  }
}
