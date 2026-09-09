import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mart/core/utils/sizer.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../dependencies_injection.dart';
import '../../data/models/category_model.dart';
import '../../domain/repository/home_repository.dart';
import '../cubit/category_products_cubit.dart';
import '../page/category_list_page.dart';
import '../page/category_products_page.dart';
import 'category_item.dart';

class CategoryCard extends StatelessWidget {
  final List<CategoryModel> categories;

  const CategoryCard({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'categories'.tr(),
                style: TextStyle(
                  fontSize: AppDimens.s16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (categories.length > 6)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryListPage(),
                      ),
                    );
                  },
                  child: Row(
                    spacing: AppDimens.s5,
                    children: [
                      Text(
                        'see_all'.tr(),
                        style: TextStyle(
                          fontSize: AppDimens.s16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      ),
                      Icon(
                        CupertinoIcons.arrow_right,
                        size: AppDimens.s16,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: AppDimens.s10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
          child: Row(
            children: categories.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: dWith(context) / 4.5,
                  child: CategoryItem(
                    category: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => CategoryProductsCubit(
                              homeRepository: sl<HomeRepository>(),
                              categoryId: item.id ?? 0,
                            )..getProducts(),
                            child: CategoryProductsPage(
                              category: item,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
