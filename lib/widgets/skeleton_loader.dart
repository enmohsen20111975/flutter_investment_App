// ============================================================================
// مساعد الاستثمار Flutter - Skeleton Loading Widgets
// Shimmer effect placeholders for loading states
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/colors.dart';

/// Skeleton box - rectangular shimmer placeholder
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceMuted.withValues(alpha: 0.3),
      highlightColor: AppColors.surface.withValues(alpha: 0.6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton card - card-shaped shimmer placeholder
class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceMuted.withValues(alpha: 0.3),
        highlightColor: AppColors.surface.withValues(alpha: 0.6),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Skeleton list - multiple card placeholders
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonCard(
        height: itemHeight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }
}

/// Skeleton stock item - simulates a stock card with icon, text lines, and price
class SkeletonStockItem extends StatelessWidget {
  const SkeletonStockItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceMuted.withValues(alpha: 0.3),
      highlightColor: AppColors.surface.withValues(alpha: 0.6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon placeholder (circle)
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Text lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Price placeholder
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 70,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 50,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton chart - chart placeholder
class SkeletonChart extends StatelessWidget {
  final double height;

  const SkeletonChart({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceMuted.withValues(alpha: 0.3),
        highlightColor: AppColors.surface.withValues(alpha: 0.6),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Skeleton dashboard - full dashboard placeholder
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Market status banner placeholder
          const SkeletonBox(height: 40),
          const SizedBox(height: 16),
          // Indices row
          Row(
            children: const [
              SizedBox(width: 16),
              Expanded(child: SkeletonBox(height: 80)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 80)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 80)),
              SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 16),
          // Chart placeholder
          const SkeletonChart(),
          const SizedBox(height: 16),
          // Stock list
          const SkeletonList(itemCount: 3),
        ],
      ),
    );
  }
}

/// Skeleton portfolio - portfolio placeholder
class SkeletonPortfolio extends StatelessWidget {
  const SkeletonPortfolio({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Summary cards
          Row(
            children: const [
              SizedBox(width: 16),
              Expanded(child: SkeletonBox(height: 100)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 100)),
              SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 16),
          // Tabs
          const SkeletonBox(height: 40),
          const SizedBox(height: 16),
          // Positions
          const SkeletonList(itemCount: 4),
        ],
      ),
    );
  }
}

/// Skeleton stock detail - stock detail page placeholder
class SkeletonStockDetail extends StatelessWidget {
  const SkeletonStockDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const SkeletonBox(height: 30),
          const SizedBox(height: 8),
          const SkeletonBox(height: 50),
          const SizedBox(height: 16),
          const SkeletonChart(),
          const SizedBox(height: 16),
          // Tabs
          const SkeletonBox(height: 40),
          const SizedBox(height: 16),
          const SkeletonList(itemCount: 3),
        ],
      ),
    );
  }
}

/// Skeleton AI analysis - AI analysis page placeholder
class SkeletonAiAnalysis extends StatelessWidget {
  const SkeletonAiAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const SkeletonBox(height: 30),
          const SizedBox(height: 16),
          const SkeletonCard(height: 150),
          const SizedBox(height: 16),
          const SkeletonCard(height: 200),
          const SizedBox(height: 16),
          const SkeletonList(itemCount: 2),
        ],
      ),
    );
  }
}

/// Skeleton recommendations - recommendations page placeholder
class SkeletonRecommendations extends StatelessWidget {
  const SkeletonRecommendations({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const SkeletonBox(height: 40),
          const SizedBox(height: 16),
          const SkeletonList(itemCount: 4),
        ],
      ),
    );
  }
}
