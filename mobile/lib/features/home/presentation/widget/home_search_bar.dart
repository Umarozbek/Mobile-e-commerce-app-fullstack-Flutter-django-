import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mart/core/constans/app_colors.dart';
import 'package:mart/core/constans/app_sizes.dart';
import 'package:mart/gen/assets.gen.dart';
import 'package:mart/features/favourites/presentation/page/favourites_page.dart';
import 'package:mart/features/main/presentation/cubit/main_cubit.dart';

import '../../../notifications/presentation/page/notifications_page.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
      child: Row(
        children: [

          Expanded(
            child: GestureDetector(
              onTap: () {
                // Switch to Search tab (index 1) and focus search
                context.read<MainCubit>().changeTab(1, focusSearch: true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.s12,
                  vertical: AppDimens.s12, // Increased height slightly
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderDark
                        :AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      Assets.icons.searchOutline,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).hintColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: AppDimens.s10),
                    Text(
                      'search_hint'.tr(), // "Mahsulotni qidiring.."
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // const SizedBox(width: AppDimens.s12),
          // IconButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //         const NotificationsPage(),
          //       ),
          //     );
          //   },
          //   icon: Icon(CupertinoIcons.bell,color: Theme.of(context).brightness == Brightness.dark
          //       ? Colors.white
          //       : AppColors.primaryText,),
          // ),
          // const SizedBox(width: AppDimens.s8),
          // GestureDetector(
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => FavouritesPage(),
          //       ),
          //     );
          //   },
          //   child: SvgPicture.asset(
          //     Assets.icons.heart,
          //     width: 24,
          //     height: 24,
          //     colorFilter: ColorFilter.mode(
          //       Theme.of(context).brightness == Brightness.dark
          //           ? Colors.white
          //           : AppColors.primaryText,
          //       BlendMode.srcIn,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
