import 'package:flutter/material.dart';
import 'package:mart/core/constans/app_sizes.dart';

import '../../../../core/constans/app_colors.dart';

/// Tab bar in a single rounded container; pill slides smoothly with page swipe.
class PillTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabs;

  static const double _height = AppDimens.s50;
  static const double _radius = AppDimens.r20;

  const PillTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final count = tabs.length;
    if (count == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary;
    final containerBorder = isDark ? AppColors.borderDark : AppColors.border;
    final activePillBg = isDark ? const Color(0xFF2D4A5E) : const Color(0xFFD7E0E7);
    final activeText = isDark ? AppColors.primaryTextDark : AppColors.primaryText;
    final inactiveText = isDark ? AppColors.secondaryTextDark : AppColors.secondaryText;

    return Container(
      height: _height,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.s10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: containerBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth;
            final tabWidth = contentWidth / count;

            // Ensure we listen to the animation if available, otherwise fallback to controller
            final animation = controller.animation;
            return AnimatedBuilder(
              animation: animation ?? controller,
              builder: (context, child) {
                // controller.animation provides smooth value for both clicks and swipes
                final position = animation?.value ?? controller.index.toDouble();
                final pillWidth = (tabWidth - 4).clamp(0.0, double.infinity);
                final pillLeft = (position * tabWidth + 2)
                    .clamp(2.0, contentWidth - pillWidth - 2);

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Sliding pill (synced with TabController animation)
                    Positioned(
                      left: pillLeft,
                      top: 0,
                      bottom: 0,
                      width: pillWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: activePillBg,
                          borderRadius: BorderRadius.circular(_radius - 4),
                        ),
                      ),
                    ),
                    // Tab labels
                    Row(
                      children: List.generate(
                        count,
                        (index) => Expanded(
                          child: GestureDetector(
                            onTap: () => controller.animateTo(index),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Text(
                                tabs[index],
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppDimens.s12,
                                  fontWeight: controller.index == index
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: controller.index == index
                                      ? activeText
                                      : inactiveText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
