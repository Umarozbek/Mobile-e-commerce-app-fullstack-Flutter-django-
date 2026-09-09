import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mart/core/extention/padding_extention.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../favourites/presentation/cubit/favourites_cubit.dart';
import '../../../favourites/presentation/page/favourites_page.dart';
import '../../../loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import '../../../notifications/presentation/cubit/news_cubit.dart';
import '../../../notifications/presentation/page/notifications_page.dart';
import '../../../b2b/presentation/page/b2b_registration_page.dart';
import '../../data/models/product_model.dart';
import '../cubit/home_cubit.dart';
import '../widget/category_card.dart';
import '../widget/category_shimmer.dart';
import '../widget/home_cards.dart';
import '../widget/home_news_widget.dart';
import '../widget/home_search_bar.dart';
import '../widget/home_shimmer.dart';
import '../widget/loyalty_card_widget.dart';
import '../widget/pill_tab_bar.dart';
import '../widget/products_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<NestedScrollViewState> _nestedKey = GlobalKey<NestedScrollViewState>();
  bool _showScrollToTop = false;

  List<String> get _tabs =>
      ['all'.tr(), 'top'.tr(), 'sales'.tr(), 'news'.tr()];
  final Map<String, bool> _isLoadingMore = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  void _loadData() {
    context.read<HomeCubit>().getCategories();
    context.read<HomeCubit>().getBanners();
    context.read<HomeCubit>().getGoodsList();
    context.read<HomeCubit>().getPopularGoodsList();
    context.read<HomeCubit>().getSaleGoodsList();
    context.read<LoyaltyCardCubit>().getBonusList();
    // Initialize favourites list for proper sync across the app
    context.read<FavouritesCubit>().getFavouritesList();
    // Load news for the news tab
    context.read<NewsCubit>().loadNews();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.axis == Axis.vertical) {
        final bool shouldShow = (_nestedKey.currentState?.outerController.offset ?? 0) > 200 ||
            (_nestedKey.currentState?.innerController.offset ?? 0) > 200;
        if (shouldShow != _showScrollToTop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showScrollToTop = shouldShow;
              });
            }
          });
        }
      }

      final metrics = notification.metrics;
      // Check if we're near the bottom (200px from bottom)
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        final cubit = context.read<HomeCubit>();
        final state = cubit.state;

        if (state is HomeSuccess) {
          // Determine which tab is active
          String activeType;
          switch (_tabController.index) {
            case 0:
              activeType = 'goods';
              break;
            case 1:
              activeType = 'popularGoods';
              break;
            case 2:
              activeType = 'saleGoods';
              break;
            case 3:
              activeType = 'newGoods';
              break;
            default:
              return false;
          }

          // Agar TOP yoki Chegirmalar bo'sh bo'lsa, lekin asosiy goods bor bo'lsa,
          // pagination uchun goods ma'lumotlaridan foydalanamiz.
          String effectiveTypeForPaging = activeType;
          if ((activeType == 'popularGoods' || activeType == 'saleGoods') &&
              extractProducts(
                      activeType == 'popularGoods'
                          ? state.popularGoods
                          : state.saleGoods)
                  .isEmpty &&
              extractProducts(state.goods).isNotEmpty) {
            effectiveTypeForPaging = 'goods';
          }

          final hasMore = state.hasMore[effectiveTypeForPaging] ?? false;
          final isLoadingMore =
              state.loadingStates['${effectiveTypeForPaging}More'] == true;

          if (hasMore &&
              !isLoadingMore &&
              !(_isLoadingMore[activeType] ?? false)) {
            _isLoadingMore[activeType] = true;
            switch (effectiveTypeForPaging) {
              case 'goods':
                cubit.loadMoreGoods();
                break;
              case 'popularGoods':
                cubit.loadMorePopularGoods();
                break;
              case 'saleGoods':
                cubit.loadMoreSaleGoods();
                break;
              case 'newGoods':
                cubit.loadMoreNewGoods();
                break;
            }
          }
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        surfaceTintColor: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'MILLION',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppDimens.s20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('MARKET'),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const NotificationsPage(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.bell),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavouritesPage(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.heart),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const B2BRegistrationPage(),
                  ),
                );
              },
              icon: const Icon(Icons.storefront_rounded),
            ),
          ],
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: () {
                _nestedKey.currentState?.innerController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
                _nestedKey.currentState?.outerController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: const Icon(CupertinoIcons.arrow_up, color: Colors.white),
            )
          : null,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          // Agar hali hech narsa yuklanmagan bo'lsa
          if (state is HomeInitial) {
            return const HomeShimmer();
          }

          // Agar HomeSuccess bo'lsa, ma'lumotlarni ko'rsatish
          if (state is HomeSuccess) {
            final bool isCategoriesLoading =
                state.loadingStates['categories'] == true;
            final bool isBannersLoading =
                state.loadingStates['banners'] == true;
            final bool hasCategories =
                state.categories != null && state.categories!.isNotEmpty;
            // Banners tipi BannerModel, shuning uchun results bo‘yicha tekshiramiz
            final bool hasBanners = state.banners != null &&
                (state.banners.results is List &&
                    (state.banners.results as List).isNotEmpty);

            final bool hasGoods = extractProducts(state.goods).isNotEmpty;
            final bool hasPopularGoods = extractProducts(state.popularGoods).isNotEmpty;
            final bool hasSaleGoods = extractProducts(state.saleGoods).isNotEmpty;
            
            final bool hasAnyGoods = hasGoods || hasPopularGoods || hasSaleGoods;

            final bool isGoodsLoading = state.loadingStates['goods'] == true;
            final bool isPopularGoodsLoading = state.loadingStates['popularGoods'] == true;
            final bool isSaleGoodsLoading = state.loadingStates['saleGoods'] == true;
            
            final bool isAnyGoodsLoading = isGoodsLoading || isPopularGoodsLoading || isSaleGoodsLoading;

            // Tabs are always shown (news tab is always available)
            const bool showTabs = true;
            final bool hasAnyData = hasCategories || hasBanners || hasAnyGoods;
            final bool hasAnyError = state.errorStates.values.any((e) => e != null);

            // Agar umuman malumot yo'q bo'lsa va yuklash ham bo'lmasa qayta yuklash tugmasini ko'rsatamiz
            if (!hasAnyData && !isCategoriesLoading && !isBannersLoading && !isAnyGoodsLoading) {
              return CommonErrorWidget(
                message: hasAnyError 
                    ? (state.errorStates.values.firstWhere((e) => e != null)?.error ?? 'error'.tr())
                    : 'no_data'.tr(),
                onRetry: _loadData,
              );
            }

            // Show shimmer if main content is loading and not yet available
            if ((isCategoriesLoading && !hasCategories) ||
                (isBannersLoading && !hasBanners)) {
              return const HomeShimmer();
            }
            return SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: NestedScrollView(
                    key: _nestedKey,
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [

                        SliverToBoxAdapter(
                          child: SafeArea(
                            child: Column(
                              children: [
                                SizedBox(height: AppDimens.s20),
                                const HomeSearchBar(),
                                SizedBox(height: AppDimens.s10),
                                if (hasBanners)
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      HomeCards(model: state.banners),
                                      if (isBannersLoading)
                                        Positioned(
                                          top: 8,
                                          child: Container(
                                            padding: EdgeInsets.all(AppDimens.s8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDark?AppColors.bgTertiaryDark:Colors.white
                                            ),
                                            width: 40,
                                            height: 40,
                                            child: CircularProgressIndicator(

                                                strokeWidth: 4),
                                          ),
                                        ),
                                    ],
                                  )
                                else if (isBannersLoading)
                                  const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: CircularProgressIndicator(

                                          strokeWidth: 2),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                SizedBox(height: AppDimens.s16),
                                SizedBox(height: AppDimens.s20),
                              ],
                            ),
                          ),
                        ),

                        // Categories (Independent of Banners) — yuklanayotganda shimmer, bo'sh/error bo'lsa reload tugmasi
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              if (state.loadingStates['categories'] == true &&
                                  (state.categories == null ||
                                      state.categories!.isEmpty))
                                const CategoryShimmer()
                              else if (state.categories != null &&
                                  state.categories!.isNotEmpty)
                                CategoryCard(categories: state.categories!)
                              else
                                const SizedBox.shrink(),
                              SizedBox(height: AppDimens.s16),
                            ],
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const LoyaltyCardWidget(),
                              SizedBox(height: AppDimens.s20),
                            ],
                          ),
                        ),

                        // Sticky TabBar
                        if (showTabs)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyTabBarDelegate(
                              child: PillTabBar(
                                controller: _tabController,
                                tabs: _tabs,
                              ).paddingOnly(
                                  top: AppDimens.s10, bottom: AppDimens.s20),
                            ),
                          ),
                      ];
                    },
                    body: showTabs
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              // Hammasi (All Goods)
                              _buildTabContent(context, state, 'goods'),
                              // Top (Popular Goods)
                              _buildTabContent(context, state, 'popularGoods'),

                              // Chegirmalar (Sale Goods)
                              _buildTabContent(context, state, 'saleGoods'),

                              // Yangiliklar (News)
                              _buildNewsTab(context),
                            ],
                          )
                        : (hasAnyError
                            ? CommonErrorWidget(
                                message: state.errorStates.values.firstWhere((e) => e != null, orElse: () => null)?.error ?? 'error'.tr(),
                                onRetry: _loadData,
                              )
                            : const SizedBox.shrink()),
              ))
            );
          }

          // Error state
          if (state is HomeError) {
            return CommonErrorWidget(
              message: state.failure.error,
              onRetry: _loadData,
            );
          }

          return const HomeShimmer();
        },
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    HomeSuccess state,
    String type,
  ) {
    dynamic productsData;
    bool isLoading;
    String? error;
    bool isLoadingMore;

    switch (type) {
      case 'goods':
        productsData = state.goods;
        isLoading = state.loadingStates['goods'] == true;
        error = state.errorStates['goods']?.error;
        isLoadingMore = state.loadingStates['goodsMore'] == true;
        break;
      case 'popularGoods':
        productsData = state.popularGoods;
        isLoading = state.loadingStates['popularGoods'] == true;
        error = state.errorStates['popularGoods']?.error;
        isLoadingMore = state.loadingStates['popularGoodsMore'] == true;
        break;
      case 'saleGoods':
        productsData = state.saleGoods;
        isLoading = state.loadingStates['saleGoods'] == true;
        error = state.errorStates['saleGoods']?.error;
        isLoadingMore = state.loadingStates['saleGoodsMore'] == true;
        break;
      case 'newGoods':
        productsData = state.newGoods;
        isLoading = state.loadingStates['newGoods'] == true;
        error = state.errorStates['newGoods']?.error;
        isLoadingMore = state.loadingStates['newGoodsMore'] == true;
        break;
      default:
        productsData = null;
        isLoading = false;
        error = null;
        isLoadingMore = false;
    }

    // Reset loading state when data is loaded
    if (!isLoadingMore && _isLoadingMore[type] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoadingMore[type] = false;
          });
        }
      });
    }

    // Agar TOP yoki Chegirmalar bo'sh bo'lib kelsa,
    // asosiy barcha mahsulotlar (`goods`) dan fallback sifatida foydalanamiz.
    dynamic effectiveProductsData = productsData;
    if ((type == 'popularGoods' || type == 'saleGoods') &&
        extractProducts(productsData).isEmpty &&
        !isLoading) {
      effectiveProductsData = state.goods;
    }

    // Extract products and limit to 30
    final allProducts = extractProducts(effectiveProductsData);
    final limitedProducts = allProducts.take(30).toList();

    // Create limited products data
    dynamic limitedProductsData;
    if (effectiveProductsData is ProductResponse) {
      limitedProductsData = ProductResponse(
        count: effectiveProductsData.count,
        next: effectiveProductsData.next,
        previous: effectiveProductsData.previous,
        results: limitedProducts.cast<ProductModel>(),
      );
    } else {
      limitedProductsData = limitedProducts;
    }

    final productsList = ProductsList(
      productsData: limitedProductsData,
      isLoading: isLoading,
      error: error,
      type: type,
      fromHome: true,
      hasMore: false,
      isLoadingMore: false,
      onRetry: () {
        switch (type) {
          case 'goods':
            context.read<HomeCubit>().getGoodsList();
            break;
          case 'popularGoods':
            context.read<HomeCubit>().getPopularGoodsList();
            break;
          case 'saleGoods':
            context.read<HomeCubit>().getSaleGoodsList();
            break;
        }
      },
    );

    final needsScrollFallback = isLoading ||
        (error != null && error.isNotEmpty) ||
        allProducts.isEmpty;

    Widget child;
    if (needsScrollFallback) {
      child = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: productsList,
        ),
      );
    } else {
      // Home page uchun ProductsList o'zi scroll qiladi
      child = productsList;
    }

    // Har bir tabning o'z RefreshIndicator'i bo'ladi.
    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().refresh(),
      color: AppColors.primary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      strokeWidth: 2.5,
      displacement: 70,
      child: child,
    );
  }

  Widget _buildNewsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<NewsCubit>().loadNews();
      },
      color: AppColors.primary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      strokeWidth: 2.5,
      displacement: 70,
      child: const HomeNewsWidget(fullPage: true),
    );
  }

}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  static const double _height = 80;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(height: _height, color: Colors.transparent, child: child);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
