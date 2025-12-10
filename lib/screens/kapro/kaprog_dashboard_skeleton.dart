import 'package:flutter/material.dart';

class KaprogDashboardSkeleton extends StatelessWidget {
  const KaprogDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSkeletonProfileCard(),
          const SizedBox(height: 20),
          _buildSkeletonStatisticsGrid(),
          const SizedBox(height: 20),
          _buildSkeletonApplications(),
        ],
      ),
    );
  }

  Widget _buildSkeletonProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SkeletonCircle(radius: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 120, height: 16),
                SizedBox(height: 6),
                SkeletonLine(width: 80, height: 12),
                SizedBox(height: 4),
                SkeletonLine(width: 60, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonStatisticsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(width: 60, height: 14),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SkeletonCircle(radius: 20),
              SkeletonCircle(radius: 20),
              SkeletonCircle(radius: 20),
              SkeletonCircle(radius: 20),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SkeletonLine(width: 30, height: 12),
              SkeletonLine(width: 30, height: 12),
              SkeletonLine(width: 30, height: 12),
              SkeletonLine(width: 30, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonApplications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: 120, height: 16),
        const SizedBox(height: 12),
        Column(
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLine(width: 100, height: 14),
                        SkeletonLine(width: 40, height: 20),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: SkeletonLine(height: 12)),
                        SizedBox(width: 12),
                        Expanded(child: SkeletonLine(height: 12)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SkeletonLine(width: 60, height: 30),
                        SizedBox(width: 8),
                        SkeletonLine(width: 60, height: 30),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonLine({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double radius;

  const SkeletonCircle({
    super.key,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}