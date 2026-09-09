
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../../../dependencies_injection.dart';
import '../../data/models/category_model.dart';
import '../../domain/repository/home_repository.dart';
import '../cubit/category_products_cubit.dart';
import '../cubit/home_cubit.dart';
import '../widget/category_item.dart';
import 'category_products_page.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<HomeCubit>();
    final state = cubit.state;
    if (state is HomeSuccess && state.categories == null) {
      cubit.getCategories();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<HomeCubit>().state;
    if (state is! HomeSuccess) return;
    final hasMore = state.hasMore['categories'] == true;
    final isLoadingMore = state.loadingStates['categoriesMore'] == true;
    if (!hasMore || isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      context.read<HomeCubit>().loadMoreCategories();
    }
  }

  Future<void> _onRefresh() async {
    context.read<HomeCubit>().getCategories(forceRefresh: true);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('categories'.tr()),
        surfaceTintColor: Colors.white,
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeSuccess) {
            final isLoading = state.loadingStates['categories'] == true;
            final error = state.errorStates['categories'];
            final categories = state.categories ?? [];

            if (isLoading && categories.isEmpty) {
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  padding: const EdgeInsets.all(AppDimens.s16),
                  children: List.generate(
                    6,
                    (index) => _buildCategoryShimmer(),
                  ),
                ),
              );
            }

            if (error != null && categories.isEmpty) {
              return CommonErrorWidget(
                message: error.error,
                onRetry: () => context.read<HomeCubit>().getCategories(forceRefresh: true),
                title: 'error'.tr(),
              );
            }

            if (categories.isEmpty) {
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: AppDimens.s16),
                          Text(
                            'categories_not_found'.tr(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }




            final hasMore = state.hasMore['categories'] == true;
            final isLoadingMore = state.loadingStates['categoriesMore'] == true;
            final itemCount = categories.length + (hasMore ? 1 : 0);

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppDimens.s16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: AppDimens.s10,
                  crossAxisSpacing: AppDimens.s10,
                  childAspectRatio: 0.7,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= categories.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimens.s16),
                      child: Center(
                        child: isLoadingMore
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  }
                  final category = categories[index];
                  return _buildCategoryCard(category);
                },
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return CategoryItem(
      category: category,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => CategoryProductsCubit(
                homeRepository: sl<HomeRepository>(),
                categoryId: category.id ?? 0,
              )..getProducts(),
              child: CategoryProductsPage(category: category),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: Column(
        children: [
          const ShimmerWidget(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.s12),
            child: Column(
              children: [
                const ShimmerWidget(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppDimens.s8),
                const ShimmerWidget(
                  width: 100,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
