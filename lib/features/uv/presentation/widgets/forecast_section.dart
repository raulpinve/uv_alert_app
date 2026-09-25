import 'package:app/features/uv/data/uv.dart';
import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:app/features/uv/presentation/widgets/uv_chart_painter.dart';
import 'package:app/features/uv/presentation/widgets/uv_legend_chip.dart';
import 'package:flutter/material.dart';

class ForecastSection extends StatelessWidget {
  const ForecastSection({
    super.key,
    required this.data,
    required this.fg,
    required this.bg,
    required this.dark,
  });

  final UvData data;
  final Color fg, bg;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final values = data.forecast.uv;
    var peak = 0.0;
    var peakHour = 0;
    for (var i = 0; i < values.length; i++) {
      if (values[i] > peak) {
        peak = values[i];
        peakHour = i;
      }
    }
    final currentHour = data.current.dateTime.hour;
    final peakLevel = levelFor(peak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pronóstico de hoy',
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: dark ? 0.85 : 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'pico ${peak.toStringAsFixed(1)} · ${peakHour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  color: peak < 0.5 ? const Color(0xFF1B2F5E) : peakLevel.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: UvChartPainter(
                    values: values,
                    currentHour: currentHour,
                    lineColor: dark ? Colors.white : const Color(0xFFA92B2B),
                    baseColor: fg.withValues(alpha: 0.15),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['00', '06', '12', '18', '23']
                    .map(
                      (e) => Text(
                        e,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UvLevel.values
              .map((l) => UvLegendChip(level: l, dark: dark))
              .toList(),
        ),
      ],
    );
  }
}
