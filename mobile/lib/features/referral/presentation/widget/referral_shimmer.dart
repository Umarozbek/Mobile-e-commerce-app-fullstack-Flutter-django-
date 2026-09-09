import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constans/app_sizes.dart';

class ReferralShimmer extends StatelessWidget {
  const ReferralShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey[100]!;
    final cardColor = isDark ? Colors.black26 : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card Shimmer
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppDimens.r16),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.s24),

          // Referral Code Section Shimmer
          Container(
            padding: const EdgeInsets.all(AppDimens.s24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppDimens.r16),
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 150, height: 16, color: isDark ? Colors.grey.shade700 : Colors.white),
                            const SizedBox(height: 6),
                            Container(width: 200, height: 12, color: isDark ? Colors.grey.shade700 : Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Code Box
                Shimmer.fromColors(
                   baseColor: baseColor,
                   highlightColor: highlightColor,
                   child: Container(
                     width: double.infinity,
                     height: 120,
                     decoration: BoxDecoration(
                       color: isDark ? Colors.grey.shade700 : Colors.white,
                       borderRadius: BorderRadius.circular(12),
                     ),
                   ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.s24),

          // My Invites Title
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(width: 120, height: 20, color: cardColor),
          ),
          const SizedBox(height: 12),

          // Invite List Items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: cardColor,
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                       children: [
                         Container(width: 40, height: 40, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.white, shape: BoxShape.circle)),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Container(width: 100, height: 14, color: isDark ? Colors.grey.shade700 : Colors.white),
                               const SizedBox(height: 6),
                               Container(width: 60, height: 10, color: isDark ? Colors.grey.shade700 : Colors.white),
                             ],
                           ),
                         ),
                         Container(width: 60, height: 20, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.white, borderRadius: BorderRadius.circular(10))),
                       ],
                     ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
