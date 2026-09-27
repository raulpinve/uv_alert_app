import 'package:flutter/material.dart';

class UvScreenSkeleton extends StatefulWidget {
  const UvScreenSkeleton({super.key});

  @override
  State<UvScreenSkeleton> createState() => _UvScreenSkeletonState();
}

class _UvScreenSkeletonState extends State<UvScreenSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final opacity = 0.35 + (_controller.value * 0.35);
          return Opacity(opacity: opacity, child: child);
        },
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- UvHeader ----
              Row(
                children: [
                  _box(width: 44, height: 44, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 100, height: 18, radius: 6),
                        const SizedBox(height: 6),
                        _box(width: 160, height: 13, radius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _box(width: 40, height: 40, radius: 20),
                ],
              ),

              const SizedBox(height: 20),

              // ---- UvRing ----
              Center(
                child: _circle(
                  size: 250,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _box(width: 80, height: 46, radius: 8),
                      const SizedBox(height: 8),
                      _box(width: 70, height: 14, radius: 6),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---- UvLevelChip ----
              Center(child: _box(width: 90, height: 26, radius: 20)),

              const SizedBox(height: 8),

              // ---- "cielo despejado: X uv" ----
              Center(child: _box(width: 140, height: 13, radius: 6)),

              const SizedBox(height: 20),

              // ---- RecommendationCard ----
              _infoCard(context, withTrailing: false),

              const SizedBox(height: 12),

              // ---- ExposureCard ----
              _infoCard(context, withTrailing: true),

              const SizedBox(height: 24),

              // ---- ForecastSection ----
              Row(
                children: [
                  Expanded(child: _box(width: 150, height: 18, radius: 6)),
                  _box(width: 110, height: 24, radius: 20),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    _box(width: double.infinity, height: 110, radius: 12),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        5,
                        (_) => _box(width: 18, height: 11, radius: 4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ---- Leyenda (UvLegendChip) ----
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  6,
                  (_) => _box(width: 64, height: 26, radius: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, {required bool withTrailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _circle(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 130, height: 15, radius: 6),
                const SizedBox(height: 8),
                _box(width: double.infinity, height: 12, radius: 6),
                const SizedBox(height: 6),
                _box(width: 180, height: 12, radius: 6),
              ],
            ),
          ),
          if (withTrailing) ...[
            const SizedBox(width: 12),
            _box(width: 44, height: 16, radius: 6),
          ],
        ],
      ),
    );
  }

  Widget _circle({required double size, Widget? child}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }

  Widget _box({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
