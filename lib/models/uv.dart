class UvResponse {
  UvResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final UvData data;

  factory UvResponse.fromJson(Map<String, dynamic> json) {
    return UvResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: UvData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class Recomendacion {
  final int rangoUvId;
  final String nombre;
  final String mensaje;

  Recomendacion({
    required this.rangoUvId,
    required this.nombre,
    required this.mensaje,
  });

  factory Recomendacion.fromJson(Map<String, dynamic> json) {
    return Recomendacion(
      rangoUvId: json['rango_uv_id'] as int,
      nombre: json['nombre'] as String,
      mensaje: json['mensaje'] as String,
    );
  }
}

class UvData {
  UvData({
    required this.ciudad,
    required this.actual,
    required this.proyeccion,
    required this.timezone,
    this.recomendacion,
  });

  final String ciudad;
  final UvActual actual;
  final UvProyeccion proyeccion;
  final String timezone;
  final Recomendacion? recomendacion;

  factory UvData.fromJson(Map<String, dynamic> json) {
    return UvData(
      ciudad: json['ciudad'] as String,
      actual: UvActual.fromJson(json['actual']),
      proyeccion: UvProyeccion.fromJson(json['proyeccion']),
      timezone: json['timezone'] as String,
      recomendacion: json['recomendacion'] != null
          ? Recomendacion.fromJson(json['recomendacion'])
          : null,
    );
  }
}

class UvActual {
  UvActual({required this.uv, required this.uvClearSky, required this.hora});

  final double uv;
  final double uvClearSky;
  final DateTime hora;

  factory UvActual.fromJson(Map<String, dynamic> json) {
    return UvActual(
      uv: (json['uv'] as num).toDouble(),
      uvClearSky: (json['uv_clear_sky'] as num).toDouble(),
      hora: DateTime.parse(json['hora'] as String),
    );
  }
}

class UvProyeccion {
  UvProyeccion({
    required this.horas,
    required this.uv,
    required this.uvClearSky,
  });

  final List<DateTime> horas;
  final List<double> uv;
  final List<double> uvClearSky;

  factory UvProyeccion.fromJson(Map<String, dynamic> json) {
    return UvProyeccion(
      horas: (json['horas'] as List)
          .map((h) => DateTime.parse(h as String))
          .toList(),
      uv: (json['uv'] as List).map((v) => (v as num).toDouble()).toList(),
      uvClearSky: (json['uv_clear_sky'] as List)
          .map((v) => (v as num).toDouble())
          .toList(),
    );
  }

  /// Combina horas + valores en una sola lista de puntos, para
  /// que sea más fácil filtrar/mapear en la UI.
  List<UvHourPoint> get points => List.generate(
    horas.length,
    (i) => UvHourPoint(hora: horas[i], uv: uv[i], uvClearSky: uvClearSky[i]),
  );
}

/// Punto individual: una hora del día con su valor de UV.
class UvHourPoint {
  UvHourPoint({required this.hora, required this.uv, required this.uvClearSky});

  final DateTime hora;
  final double uv;
  final double uvClearSky;
}
