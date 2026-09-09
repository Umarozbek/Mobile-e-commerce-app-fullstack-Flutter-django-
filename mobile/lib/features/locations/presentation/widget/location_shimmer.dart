import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_colors.dart';

class LocationShimmer extends StatelessWidget {
  const LocationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.s16),
      itemCount: 4, 
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.s12),
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey.shade700 : Colors.grey[100]!,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.s12, 
                vertical: AppDimens.s16, // Matching card height approx
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.r12),
              ),
              child: Row(
                children: [
                  // Icon placeholder
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimens.s12),
                  // Address text placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14,
                          color: isDark ? Colors.grey.shade700 : Colors.white,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 150,
                          height: 12,
                          color: isDark ? Colors.grey.shade700 : Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Action buttons placeholders
                  Row(
                    children: [
                      Container(width: 20, height: 20, color: isDark ? Colors.grey.shade700 : Colors.white),
                      const SizedBox(width: 12),
                      Container(width: 20, height: 20, color: isDark ? Colors.grey.shade700 : Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
