// lib/widgets/loading_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.divider,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class QuestionCardShimmer extends StatelessWidget {
  const QuestionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags row
          Row(
            children: [
              ShimmerBox(width: 60, height: 20, radius: 6),
              const SizedBox(width: 8),
              ShimmerBox(width: 80, height: 20, radius: 6),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          ShimmerBox(width: double.infinity, height: 16),
          const SizedBox(height: 6),
          ShimmerBox(width: 220, height: 16),
          const SizedBox(height: 12),
          // Body
          ShimmerBox(width: double.infinity, height: 12),
          const SizedBox(height: 4),
          ShimmerBox(width: 300, height: 12),
          const SizedBox(height: 16),
          // Footer
          Row(
            children: [
              ShimmerBox(width: 40, height: 24, radius: 12),
              const SizedBox(width: 12),
              ShimmerBox(width: 60, height: 24, radius: 12),
              const Spacer(),
              ShimmerBox(width: 80, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class QuestionListShimmer extends StatelessWidget {
  final int count;
  const QuestionListShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => const QuestionCardShimmer(),
    );
  }
}
