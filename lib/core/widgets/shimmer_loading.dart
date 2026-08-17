import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -1.0, max: 2.0, period: const Duration(milliseconds: 1400));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: const [
                Color(0xFF1B2026),
                Color(0xFF2C353F),
                Color(0xFF1B2026),
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 6,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2026),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Home Feed Skeleton
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Quick Picks
          const ShimmerBox(width: 190, height: 20, borderRadius: 4),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.8,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B2026),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  ShimmerBox(width: 52, height: 52, borderRadius: 6),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerBox(width: 90, height: 12, borderRadius: 3),
                        SizedBox(height: 6),
                        ShimmerBox(width: 55, height: 10, borderRadius: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 2. Albums Shelf
          const ShimmerBox(width: 170, height: 20, borderRadius: 4),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 130, height: 130, borderRadius: 8),
                  SizedBox(height: 8),
                  ShimmerBox(width: 110, height: 12, borderRadius: 3),
                  SizedBox(height: 6),
                  ShimmerBox(width: 75, height: 10, borderRadius: 3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 3. Artists
          const ShimmerBox(width: 140, height: 20, borderRadius: 4),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, __) => const Column(
                children: [
                  ShimmerBox(width: 80, height: 80, shape: BoxShape.circle),
                  SizedBox(height: 8),
                  ShimmerBox(width: 60, height: 10, borderRadius: 3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 4. Playlists
          const ShimmerBox(width: 180, height: 20, borderRadius: 4),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 130, height: 130, borderRadius: 8),
                  SizedBox(height: 8),
                  ShimmerBox(width: 100, height: 12, borderRadius: 3),
                  SizedBox(height: 6),
                  ShimmerBox(width: 60, height: 10, borderRadius: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spotify Tracklist Skeleton
class SongListSkeleton extends StatelessWidget {
  final int itemCount;
  const SongListSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const Row(
          children: [
            ShimmerBox(width: 44, height: 44, borderRadius: 6),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: 3),
                  SizedBox(height: 6),
                  ShimmerBox(width: 120, height: 11, borderRadius: 3),
                ],
              ),
            ),
            SizedBox(width: 12),
            ShimmerBox(width: 20, height: 20, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}