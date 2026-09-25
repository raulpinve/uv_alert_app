// lib/features/uv/presentation/widgets/uv_header.dart
import 'package:app/features/uv/data/uv.dart';
import 'package:flutter/material.dart';

const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sept',
  'oct',
  'nov',
  'dic',
];

class UvHeader extends StatelessWidget {
  const UvHeader({
    super.key,
    required this.data,
    required this.fg,
    required this.onRefresh,
    required this.dark,
    required this.onProfile,
  });

  final UvData data;
  final Color fg;
  final VoidCallback onRefresh;
  final bool dark;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final t = data.current.dateTime;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final fecha =
        '${_dias[t.weekday - 1]} ${t.day} de ${_meses[t.month - 1]} · $hh:$mm';
    final box = Colors.white.withValues(alpha: dark ? 0.15 : 0.55);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: box,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.location_on_outlined, color: fg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.city,
                style: TextStyle(
                  color: fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                fecha,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onRefresh,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: box, shape: BoxShape.circle),
            child: Icon(Icons.refresh, color: fg, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onProfile,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: box, shape: BoxShape.circle),
            child: Icon(Icons.person_outline, color: fg, size: 20),
          ),
        ),
      ],
    );
  }
}
