import 'package:flutter/material.dart';

class CloudReductionChip extends StatelessWidget {
  const CloudReductionChip({
    super.key,
    required this.uv,
    required this.uvClearSky,
    required this.fg,
    required this.dark,
  });

  final double uv;
  final double uvClearSky;
  final Color fg;
  final bool dark;

  double get _reductionPercent {
    if (uvClearSky <= 0) return 0;
    return ((uvClearSky - uv) / uvClearSky * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final reduction = _reductionPercent;
    if (reduction < 5) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dark ? 0.85 : 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 14,
            color: fg.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'nubes reducen ${reduction.toStringAsFixed(0)}%',
            style: TextStyle(
              color: fg.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
