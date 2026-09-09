import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/widget/product_card.dart';
import '../cubit/favourites_cubit.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  @override
  void initState() {
    super.initState();
    context.read<FavouritesCubit>().getFavouritesList();
  }

  Future<void> _onRefresh() async {
    await context.read<FavouritesCubit>().getFavouritesList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('favorite'.tr()),
        elevation: 1,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),
        scrolledUnderElevation: 1,
      ),
      body: BlocBuilder<FavouritesCubit, FavouritesState>(
        builder: (context, state) {
          if (state is FavouritesLoading) {
            return _buildLoadingState();
          }

          if (state is FavouritesError) {
            return CommonErrorWidget(
              message: state.failure.error,
              onRetry: () => context.read<FavouritesCubit>().getFavouritesList(),
              title: 'error'.tr(),
            );
          }

          if (state is FavouritesSuccess) {
            final favourites = state.favouriteProducts;

            if (favourites.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.s5,
                      vertical: AppDimens.s8,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.66,
                        mainAxisSpacing: AppDimens.s8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ProductCard(
                            product: favourites[index],
                            productType: 'favorites',
                          );
                        },
                        childCount: favourites.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.s5,
            vertical: AppDimens.s8,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.66,
              mainAxisSpacing: AppDimens.s8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget(
                        width: double.infinity,
                        height: 200,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.r12)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(AppDimens.s10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerWidget(
                              width: double.infinity,
                              height: 16,
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                            SizedBox(height: AppDimens.s8),
                            ShimmerWidget(
                              width: 100,
                              height: 20,
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.heart, 
                    size: 100, 
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: AppDimens.s24),
                  Text(
                    'favourites_empty_title'.tr(),
                    style: TextStyle(
                      fontSize: AppDimens.s20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: AppDimens.s8),
                  Text(
                    'favourites_empty_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimens.s14, 
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
