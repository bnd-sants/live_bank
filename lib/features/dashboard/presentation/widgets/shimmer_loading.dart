import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildShimmerCard(baseColor, highlightColor, height: 120),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildShimmerCard(baseColor, highlightColor, height: 100)),
            const SizedBox(width: 16),
            Expanded(child: _buildShimmerCard(baseColor, highlightColor, height: 100)),
          ],
        ),
        const SizedBox(height: 32),
        _buildShimmerCard(baseColor, highlightColor, height: 250),
        const SizedBox(height: 32),
        _buildShimmerText(baseColor, highlightColor),
        const SizedBox(height: 16),
        ...List.generate(5, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildShimmerListItem(baseColor, highlightColor),
        )),
      ],
    );
  }

  Widget _buildShimmerCard(Color base, Color highlight, {required double height}) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildShimmerText(Color base, Color highlight) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: 20,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildShimmerListItem(Color base, Color highlight) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: double.infinity, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 10, width: 100, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 60, height: 20, color: Colors.white),
        ],
      ),
    );
  }
}
