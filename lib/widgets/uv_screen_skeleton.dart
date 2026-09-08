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
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.35 + (_controller.value * 0.35);

        return Opacity(opacity: opacity, child: child);
      },
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ciudad
            _box(width: 120, height: 18, radius: 6),

            const SizedBox(height: 20),

            // Tarjeta principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _box(width: 150, height: 18, radius: 6),

                  const SizedBox(height: 20),

                  _box(width: 100, height: 70, radius: 12),

                  const SizedBox(height: 16),

                  _box(width: 120, height: 20, radius: 6),

                  const SizedBox(height: 8),

                  _box(width: 170, height: 14, radius: 6),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Título sección
            _box(width: 140, height: 22, radius: 6),

            const SizedBox(height: 16),

            // Horas
            SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) {
                  return Container(
                    width: 90,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _box(width: 45, height: 14, radius: 5),
                        const SizedBox(height: 14),
                        _box(width: 30, height: 30, radius: 15),
                        const SizedBox(height: 10),
                        _box(width: 35, height: 12, radius: 5),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
