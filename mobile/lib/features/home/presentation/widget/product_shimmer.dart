import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constans/app_sizes.dart';

/// Kategoriya mahsulotlari yuklanayotganda ko'rsatiladigan product card shaklidagi shimmer.
/// CategoryProductsPage va boshqa mahsulot ro'yxati ekranlarida ishlatiladi.
class ProductShimmer extends StatelessWidget {
  const ProductShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final containerColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.s5,
        vertical: AppDimens.s8,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            _buildShimmerRow(context, containerColor),
            const SizedBox(height: AppDimens.s8),
            _buildShimmerRow(context, containerColor),
            const SizedBox(height: AppDimens.s8),
            _buildShimmerRow(context, containerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerRow(BuildContext context, Color containerColor) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppDimens.s5 * 2;
    final spacing = AppDimens.s8;
    final cardWidth = (width - padding - spacing) / 2;
    final cardHeight = cardWidth / 0.66;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _ProductCardShimmer(containerColor: containerColor),
        ),
        const SizedBox(width: AppDimens.s8),
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _ProductCardShimmer(containerColor: containerColor),
        ),
      ],
    );
  }
}

class _ProductCardShimmer extends StatelessWidget {
  final Color containerColor;

  const _ProductCardShimmer({required this.containerColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: containerColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rasm joyi (product card aspect ratio bo'yicha yuqori qismi)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimens.r12),
                ),
              ),
            ),
          ),
          // Sarlavha va narx
          Padding(
            padding: const EdgeInsets.all(AppDimens.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(AppDimens.r4),
                  ),
                ),
                const SizedBox(height: AppDimens.s6),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(AppDimens.r4),
                  ),
                ),
                const SizedBox(height: AppDimens.s8),
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(AppDimens.r4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
