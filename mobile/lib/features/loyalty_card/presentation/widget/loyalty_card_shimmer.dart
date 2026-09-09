import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_colors.dart';

class LoyaltyCardShimmer extends StatelessWidget {
  const LoyaltyCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final itemColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.white;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
      child: Column(
        children: [
            const SizedBox(height: AppDimens.s16),
            // Loyalty Card Shimmer
            Shimmer.fromColors(
              baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: itemColor,
              child: Container(
                padding: const EdgeInsets.all(AppDimens.s24),
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: BorderRadius.circular(AppDimens.r20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 80, height: 14, color: itemColor), // Label
                    const SizedBox(height: 8),
                    Container(width: 120, height: 36, color: itemColor), // Balance
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 60, height: 12, color: itemColor), // Label
                            const SizedBox(height: 4),
                            Container(width: 150, height: 18, color: itemColor), // Name
                            const SizedBox(height: 16),
                            Container(width: 80, height: 12, color: itemColor), // Label
                            const SizedBox(height: 4),
                            Container(width: 100, height: 14, color: itemColor), // Date
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: itemColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.s24),

            // Cycle Info Shimmer
            Shimmer.fromColors(
              baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: itemColor,
              child: Container(
                padding: const EdgeInsets.all(AppDimens.s20),
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: BorderRadius.circular(AppDimens.r16),
                ),
                child: Column(
                  children: [
                    Container(width: 100, height: 16, color: itemColor), // Title
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStatItemShimmer(itemColor)),
                        Container(width: 1, height: 40, color: itemColor),
                        Expanded(child: _buildStatItemShimmer(itemColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.s24),

            // Info Section Shimmer
            Shimmer.fromColors(
              baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: itemColor,
              child: Container(
                padding: const EdgeInsets.all(AppDimens.s20),
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: BorderRadius.circular(AppDimens.r16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 18, color: itemColor), // Title
                    const SizedBox(height: 16),
                    _buildInfoItemShimmer(itemColor),
                    const SizedBox(height: 12),
                    _buildInfoItemShimmer(itemColor),
                    const SizedBox(height: 12),
                    _buildInfoItemShimmer(itemColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.s24),

            // History List Shimmer
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor: itemColor,
                  child: Container(width: 80, height: 18, color: itemColor),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Shimmer.fromColors(
                          baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
                          highlightColor: itemColor,
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: itemColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItemShimmer(Color color) {
    return Column(
      children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 8),
        Container(width: 40, height: 12, color: color),
        const SizedBox(height: 4),
        Container(width: 60, height: 16, color: color),
      ],
    );
  }

  Widget _buildInfoItemShimmer(Color color) {
    return Row(
      children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 14, color: color)),
      ],
    );
  }
}
