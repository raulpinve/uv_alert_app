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
