import 'dart:convert';

import 'package:http/http.dart' as http;

class FieldError {
  final String field;
  final String message;
  const FieldError(this.field, this.message);
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? type;
  final List<FieldError> fieldErrors;

  const ApiException(
    this.statusCode,
    this.message, {
    this.type,
    this.fieldErrors = const [],
  });

  /// Construye la excepción a partir de una respuesta HTTP del backend,
  /// cuyo shape de error es:
  /// { statusCode, message, error, errors?: [{ field, message }] }
  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      final message =
          body['message'] as String? ??
          'Error desconocido (${response.statusCode})';
      final type = body['error'] as String?;

      final rawErrors = body['errors'] as List<dynamic>?;
      final fieldErrors = rawErrors == null
          ? const <FieldError>[]
          : rawErrors
                .map(
                  (e) => FieldError(
                    (e as Map<String, dynamic>)['field'] as String? ?? '',
                    e['message'] as String? ?? '',
                  ),
                )
                .toList();

      return ApiException(
        response.statusCode,
        message,
        type: type,
        fieldErrors: fieldErrors,
      );
    } catch (_) {
      // El body no es el JSON esperado (ej. 404 HTML de Express cuando
      // la ruta no existe, o un proxy/gateway devolviendo texto plano).
      return ApiException(
        response.statusCode,
        'Error del servidor (status ${response.statusCode})',
      );
    }
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 400 && fieldErrors.isNotEmpty;

  /// Un campo puede traer varios errores de express-validator; los unimos.
  Map<String, String> get fieldErrorMap {
    final map = <String, List<String>>{};
    for (final e in fieldErrors) {
      map.putIfAbsent(e.field, () => []).add(e.message);
    }
    return map.map((k, v) => MapEntry(k, v.join('\n')));
  }

  /// Para snackbars: si hay errores por campo, muestra esos en vez del genérico.
  String get displayMessage => fieldErrors.isEmpty
      ? message
      : fieldErrors.map((e) => e.message).toSet().join('\n');

  @override
  String toString() => message;
}
