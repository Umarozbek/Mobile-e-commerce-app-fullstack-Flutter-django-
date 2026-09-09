import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mart/core/utils/sizer.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../data/models/category_model.dart';

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onTap,
  });

  static Widget _buildImageShimmer(BuildContext context, bool isDark) {
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final containerColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: containerColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  String _getLocalizedName(BuildContext context) {
    final locale = context.locale.languageCode;
    switch (locale) {
      case 'ru':
        return category.nameRu ?? category.name ?? '';
      case 'en':
        return category.nameEn ?? category.name ?? '';
      case 'ko':
        return category.nameKr ?? category.name ?? '';
      case 'uz':
      default:
        return category.nameUz ?? category.name ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _getLocalizedName(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dWith(context)/4.8,
            height: dWith(context)/4.8,
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
              // borderRadius: BorderRadius.circular(AppDimens.r12),
              shape: BoxShape.circle
            ),

            clipBehavior: Clip.antiAlias,
            child: category.image != null && category.image!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: category.image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => _buildImageShimmer(context, isDark),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.category_outlined,
                        size: AppDimens.icon24,
                        color: isDark
                            ? AppColors.disabledTextDark
                            : AppColors.disabledText,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.category_outlined,
                      size: AppDimens.icon32,
                      color: isDark
                          ? AppColors.disabledTextDark
                          : AppColors.disabledText,
                    ),
                  ),
          ),
          const SizedBox(height: AppDimens.s8),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.primaryTextDark : AppColors.primaryText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
