// lib/models/uv.dart
// Si ya tienes tu propio modelo, solo asegúrate de exponer estos mismos campos.

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

class UvResponse {
  UvResponse({required this.success, required this.message, this.data});

  final bool success;
  final String message;
  final UvData? data;

  factory UvResponse.fromJson(Map<String, dynamic> json) => UvResponse(
    success: json['success'] as bool? ?? false,
    message: json['message'] as String? ?? '',
    data: json['data'] == null
        ? null
        : UvData.fromJson(json['data'] as Map<String, dynamic>),
  );
}

class UvData {
  UvData({
    required this.city,
    required this.current,
    required this.forecast,
    required this.timezone,
    required this.recommendation,
    this.exposure,
  });

  final String city;
  final UvCurrent current;
  final UvForecast forecast;
  final String timezone;
  final UvRecommendation recommendation;
  final UvExposure? exposure;

  factory UvData.fromJson(Map<String, dynamic> json) => UvData(
    city: json['city'] as String? ?? '',
    current: UvCurrent.fromJson(json['current'] as Map<String, dynamic>),
    forecast: UvForecast.fromJson(json['forecast'] as Map<String, dynamic>),
    timezone: json['timezone'] as String? ?? '',
    recommendation: UvRecommendation.fromJson(
      json['recommendation'] as Map<String, dynamic>,
    ),
    exposure: json['exposure'] == null
        ? null
        : UvExposure.fromJson(json['exposure'] as Map<String, dynamic>),
  );
}

class UvCurrent {
  UvCurrent({required this.uv, required this.uvClearSky, required this.time});

  final double uv;
  final double uvClearSky;
  final String time; // "2026-09-23T22:30"

  DateTime get dateTime => DateTime.parse(time);

  factory UvCurrent.fromJson(Map<String, dynamic> json) => UvCurrent(
    uv: _d(json['uv']),
    uvClearSky: _d(json['uvClearSky']),
    time: json['time'] as String? ?? '',
  );
}

class UvForecast {
  UvForecast({required this.hours, required this.uv, required this.uvClearSky});

  final List<String> hours;
  final List<double> uv;
  final List<double> uvClearSky;

  factory UvForecast.fromJson(Map<String, dynamic> json) => UvForecast(
    hours: (json['hours'] as List? ?? []).cast<String>(),
    uv: (json['uv'] as List? ?? []).map(_d).toList(),
    uvClearSky: (json['uvClearSky'] as List? ?? []).map(_d).toList(),
  );
}

class UvRecommendation {
  UvRecommendation({
    required this.uvRangeId,
    required this.code,
    required this.name,
    required this.message,
  });

  final int uvRangeId;
  final String code;
  final String name;
  final String message;

  factory UvRecommendation.fromJson(Map<String, dynamic> json) =>
      UvRecommendation(
        uvRangeId: json['uvRangeId'] as int? ?? 0,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );
}

class UvExposure {
  UvExposure({
    required this.skinTypeId,
    required this.skinTypeName,
    required this.minutes,
    required this.message,
  });

  final int skinTypeId;
  final String skinTypeName;
  final int? minutes; // null cuando no hay UV significativo
  final String message;

  factory UvExposure.fromJson(Map<String, dynamic> json) => UvExposure(
    skinTypeId: json['skinTypeId'] as int? ?? 0,
    skinTypeName: json['skinTypeName'] as String? ?? '',
    minutes: (json['minutes'] as num?)?.round(),
    message: json['message'] as String? ?? '',
  );
}
