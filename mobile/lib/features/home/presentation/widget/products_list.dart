import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mart/features/home/presentation/widget/product_card.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../search/presentation/cubit/search_cubit.dart';
import '../../data/models/product_model.dart';
import '../cubit/category_products_cubit.dart';
import '../cubit/home_cubit.dart';
import '../page/all_products_page.dart';

class ProductsList extends StatefulWidget {
  final dynamic productsData;
  final bool isLoading;
  final String? error;
  final String type; // 'popularGoods', 'saleGoods', 'newGoods', 'search'
  final bool hasMore;
  final bool useScroll;
  final bool fromHome;
  final bool isLoadingMore;
  /// Xato bo'lganda "Qayta yuklash" tugmasi uchun
  final VoidCallback? onRetry;
  /// Optional header widget to show above products (e.g. news)
  final Widget? headerWidget;

  const ProductsList({
    super.key,
    required this.productsData,
    this.isLoading = false,
    this.error,
    required this.type,
    this.hasMore = false,
    this.fromHome = false,
    this.useScroll = true,
    this.isLoadingMore = false,
    this.onRetry,
    this.headerWidget,
  });

  @override
  State<ProductsList> createState() => _ProductsListState();
}

class _ProductsListState extends State<ProductsList>
    with AutomaticKeepAliveClientMixin<ProductsList> {
  bool _isLoadingMore = false;
  late ScrollController _scrollController;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    if (!widget.fromHome) {
      _scrollController = ScrollController();
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void ignore() {
    // This ignore method is a placeholder to keep the code structure if needed
    // But we are using didUpdateWidget below
  }

  @override
  void dispose() {
    if (!widget.fromHome) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.fromHome) {
      if (_scrollController.offset >= 400) {
        if (!_showScrollToTop) {
          setState(() {
            _showScrollToTop = true;
          });
        }
      } else {
        if (_showScrollToTop) {
          setState(() {
            _showScrollToTop = false;
          });
        }
      }
    }
  }

  void _scrollToTop() {
    if (!widget.fromHome) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void didUpdateWidget(ProductsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isLoadingMore = widget.isLoadingMore;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      // Check if we're near the bottom (200px from bottom)
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        if (widget.hasMore && !_isLoadingMore && !widget.isLoadingMore) {
          _isLoadingMore = true;
          
          if (widget.type == 'search') {
            context.read<SearchCubit>().loadMoreSearchResults();
          } else if (widget.type.startsWith('category_')) {
            context.read<CategoryProductsCubit>().loadMore();
          } else {
            switch (widget.type) {
              case 'goods':
                context.read<HomeCubit>().loadMoreGoods();
                break;
              case 'popularGoods':
                context.read<HomeCubit>().loadMorePopularGoods();
                break;
              case 'saleGoods':
                context.read<HomeCubit>().loadMoreSaleGoods();
                break;
              case 'newGoods':
                context.read<HomeCubit>().loadMoreNewGoods();
                break;
            }
          }
        }
      }
    }
    return false; // Allow the notification to continue bubbling
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final products = extractProducts(widget.productsData);
    // Home refresh: avvalgi mahsulotlarni ko'rsatish, shimmer/spinner ko'rsatmaslik
    final showFullScreenLoading = widget.isLoading && (!widget.fromHome || products.isEmpty);
    if (showFullScreenLoading) {
      if (widget.fromHome) {
        return _buildProductsShimmer(context);
      }
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.error != null && widget.error!.isNotEmpty) {
      return CommonErrorWidget(
        message: widget.error!,
        onRetry: widget.onRetry ?? () {},
        title: 'error'.tr(),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'search_no_results'.tr(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // For search page and all products page, use normal scroll physics
    // Always enable scrolling for lists (AllProducts, Search, Categories)
    // For Home Page, we also want scrolling to support NestedScrollView
    final useScrollablePhysics = widget.useScroll || widget.type == 'search' || widget.hasMore;
    
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          CustomScrollView(
            controller: !widget.fromHome ? _scrollController : null,
            physics: useScrollablePhysics
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            slivers: [
              if (widget.headerWidget != null)
                SliverToBoxAdapter(child: widget.headerWidget!),
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
                        product: products[index],
                        productType: widget.type,
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
              if (widget.isLoadingMore)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              // Show "See all" button only if from home and products >= 8
              if (widget.fromHome && products.length >= 8)
                _buildSeeAllButton(context, widget.type),
            ],
          ),
          if (!widget.fromHome)
            Positioned(
              bottom: 20,
              right: 20,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showScrollToTop ? 1.0 : 0.0,
                child: FloatingActionButton(
                  onPressed: _showScrollToTop ? _scrollToTop : null,
                  backgroundColor: AppColors.primary,
                  mini: true,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Home tablarda product list yuklanayotganda ko'rsatiladigan product grid shimmer'i
  Widget _buildProductsShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey[200]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.s5,
          vertical: AppDimens.s8,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.66,
          mainAxisSpacing: AppDimens.s8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppDimens.r12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(AppDimens.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppDimens.s10),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.s8),
                Container(
                  width: double.infinity,
                  height: AppDimens.s12,
                  color: isDark ? Colors.black26 : Colors.grey[100],
                ),
                const SizedBox(height: AppDimens.s4),
                Container(
                  width: AppDimens.s60,
                  height: AppDimens.s12,
                  color: isDark ? Colors.black26 : Colors.grey[100],
                ),
                const SizedBox(height: AppDimens.s8),
                Container(
                  width: double.infinity,
                  height: AppDimens.s32,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppDimens.r8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeeAllButton(BuildContext context, String type) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.s16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AllProductsPage(
                  productType: type,
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: AppDimens.s14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.r12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'see_all'.tr(),
                style: const TextStyle(
                  fontSize: AppDimens.s16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppDimens.s8),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
