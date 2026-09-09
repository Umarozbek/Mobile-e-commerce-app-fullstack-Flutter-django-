import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mart/core/utils/sizer.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/main_cubit.dart';

class MainBottom extends StatefulWidget {
  final int index;
  final Function(int) onTabChanged;

  const MainBottom({
    super.key,
    required this.index,
    required this.onTabChanged,
  });

  @override
  State<MainBottom> createState() => _MainBottomState();
}

class _MainBottomState extends State<MainBottom> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            (isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary);
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final unselectedColor =
        isDark ? AppColors.secondaryTextDark : Colors.grey.shade500;
    final selectedColor = isDark ? AppColors.primaryDark : AppColors.primary;

    // return Container(
    //   height: kBottomNavigationBarHeight+10,
    //   child: BottomNavigationBar(
    //
    //     // currentIndex: widget.index,
    //     onTap: widget.onTabChanged,
    //     // backgroundColor: backgroundColor,
    //     selectedItemColor: selectedColor,
    //     unselectedItemColor: unselectedColor,
    //     type: BottomNavigationBarType.fixed,
    //
    //     selectedLabelStyle: const TextStyle(
    //       fontSize: 12,
    //       fontWeight: FontWeight.w500,
    //     ),
    //     unselectedLabelStyle: const TextStyle(
    //       fontSize: 12,
    //       fontWeight: FontWeight.w500,
    //     ),
    //     elevation: 0,
    //     items: [
    //       BottomNavigationBarItem(
    //         icon: Padding(
    //           padding: const EdgeInsets.only(bottom: 4),
    //           child: SvgPicture.asset(
    //             Assets.icons.home,
    //             color: widget.index == 0 ? selectedColor : unselectedColor,
    //           ),
    //         ),
    //         label: "main".tr(),
    //
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Padding(
    //           padding: const EdgeInsets.only(bottom: 4),
    //           child: SvgPicture.asset(
    //             Assets.icons.searchOutline,
    //             color: widget.index == 1 ? selectedColor : unselectedColor,
    //           ),
    //         ),
    //
    //         label: "search".tr(),
    //       ),
    //
    //       // BottomNavigationBarItem(
    //       //   icon: Padding(
    //       //     padding: const EdgeInsets.only(bottom: 4),
    //       //     child: AnimatedContainer(
    //       //       duration: const Duration(milliseconds: 200),
    //       //       width: 44,
    //       //       height: 44,
    //       //       decoration: BoxDecoration(
    //       //         shape: BoxShape.circle,
    //       //         boxShadow: widget.index == 2
    //       //             ? [
    //       //           // Porloq halo — atrofida yorqin halqa
    //       //           BoxShadow(
    //       //             color: (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.5),
    //       //             blurRadius: 12,
    //       //             spreadRadius: 1,
    //       //             offset: Offset.zero,
    //       //           ),
    //       //           BoxShadow(
    //       //             color: (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.25),
    //       //             blurRadius: 20,
    //       //             spreadRadius: -2,
    //       //             offset: Offset.zero,
    //       //           ),
    //       //         ]
    //       //             : null,
    //       //         gradient: widget.index == 2
    //       //             ? LinearGradient(
    //       //           begin: Alignment.topLeft,
    //       //           end: Alignment.bottomRight,
    //       //           colors: isDark
    //       //               ? [
    //       //             const Color(0xFF3D5A6E),
    //       //             const Color(0xFF1E3A4D),
    //       //           ]
    //       //               : [
    //       //             const Color(0xFF4A6B7E),
    //       //             const Color(0xFF2A4555),
    //       //           ],
    //       //         )
    //       //             : null,
    //       //       ),
    //       //       child: Center(
    //       //         child: SvgPicture.asset(
    //       //           Assets.icons.creditCard,
    //       //           color: widget.index == 2 ? Colors.white : unselectedColor,
    //       //           width: 22,
    //       //           height: 22,
    //       //         ),
    //       //       ),
    //       //     ),
    //       //   ),
    //       //   label: "account_tab".tr(),
    //       // ),
    //       BottomNavigationBarItem(
    //         icon: BlocBuilder<CartCubit, CartState>(
    //           builder: (context, state) {
    //             int itemCount = 0;
    //             if (state is CartSuccess) {
    //               itemCount = context.read<CartCubit>().getCartItemCount();
    //             }
    //             return Padding(
    //               padding: const EdgeInsets.only(bottom: 4),
    //               child: Stack(
    //                 clipBehavior: Clip.none,
    //                 children: [
    //                   SvgPicture.asset(
    //                     Assets.icons.cart,
    //                     color: widget.index == 3
    //                         ? selectedColor
    //                         : unselectedColor,
    //                   ),
    //                   if (itemCount > 0)
    //                     Positioned(
    //                       right: -8,
    //                       top: -8,
    //                       child: Container(
    //                         padding: const EdgeInsets.all(4),
    //                         decoration: const BoxDecoration(
    //                           color: Colors.red,
    //                           shape: BoxShape.circle,
    //                         ),
    //                         constraints: const BoxConstraints(
    //                           minWidth: 16,
    //                           minHeight: 16,
    //                         ),
    //                         child: Text(
    //                           itemCount > 99 ? '99+' : itemCount.toString(),
    //                           style: const TextStyle(
    //                             color: Colors.white,
    //                             fontSize: 10,
    //                             fontWeight: FontWeight.bold,
    //                           ),
    //                           textAlign: TextAlign.center,
    //                         ),
    //                       ),
    //                     ),
    //                 ],
    //               ),
    //             );
    //           },
    //         ),
    //
    //         label: 'cart'.tr(),
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Padding(
    //           padding: const EdgeInsets.only(bottom: 4),
    //           child: SvgPicture.asset(
    //             Assets.icons.userOutline,
    //             color: widget.index == 4 ? selectedColor : unselectedColor,
    //           ),
    //         ),
    //         label: "profile".tr(),
    //       ),
    //     ],
    //   ),
    // );
    return Material(
      child: Container(
      
        decoration: BoxDecoration(
            color: isDark ? AppColors.bgSecondaryDark : Colors.white),
        height: kBottomNavigationBarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: [
            mainItem(
              child: SvgPicture.asset(
                width: 24,
                height: 24,
                Assets.icons.home,
                color: widget.index == 0 ? selectedColor : unselectedColor,
              ),
              onTap: () {
                context.read<MainCubit>().changeTab(0);
              },
            ),
            mainItem(
              child: SvgPicture.asset(
                Assets.icons.searchOutline,
                color: widget.index == 1 ? selectedColor : unselectedColor,
              ),
              onTap: () {
                context.read<MainCubit>().changeTab(1);
              },
            ),
            mainItem(
              child: SizedBox(),
              onTap: () {
                // context.read<MainCubit>().changeTab(1);
              },
            ),
            mainItem(
              child: SizedBox(
                width: 32,
                height: 32,
                child: BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    int itemCount = 0;
                    if (state is CartSuccess) {
                      itemCount = context.read<CartCubit>().getCartItemCount();
                    }
                    return Center(
                      child: SizedBox(

                        child: Badge(
                          offset: Offset(7, -5),
                          isLabelVisible: itemCount > 0,
                          alignment: Alignment.topRight, // aniq pozitsiya
                          label: Text(
                            itemCount > 99 ? '99+' : itemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          child: SvgPicture.asset(
                            Assets.icons.cart,
                            width: 24,
                            height: 24,
                            color: widget.index == 3
                                ? selectedColor
                                : unselectedColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              onTap: () {
                context.read<MainCubit>().changeTab(3);
              },
            ),
            mainItem(
              child: SvgPicture.asset(
                width: 24,
                height: 24,
                  Assets.icons.userOutline,
                  color: widget.index == 4 ? selectedColor : unselectedColor,
                ),
              onTap: () {
                context.read<MainCubit>().changeTab(4);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget mainItem({required Widget child, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(


            child: child),
      ),
    );
  }
}
