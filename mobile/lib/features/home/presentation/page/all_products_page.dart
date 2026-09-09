
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../notifications/presentation/cubit/news_cubit.dart';
import '../../data/models/product_model.dart';
import '../cubit/home_cubit.dart';
import '../widget/home_news_widget.dart';
import '../widget/pill_tab_bar.dart';
import '../widget/products_list.dart';

class AllProductsPage extends StatefulWidget {
  final String? productType; // Optional - if null, show all tabs
  final String? title; // Optional - if null, use default title

  const AllProductsPage({
    super.key,
    this.productType,
    this.title,
  });

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> get _tabs => ['all'.tr(), 'top'.tr(), 'sales'.tr(), 'news'.tr()];
  final Map<String, bool> _isLoadingMore = {};
  int _initialTabIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Determine initial tab based on productType
    if (widget.productType != null) {
      switch (widget.productType) {
        case 'goods':
          _initialTabIndex = 0;
          break;
        case 'popularGoods':
          _initialTabIndex = 1;
          break;
        case 'saleGoods':
          _initialTabIndex = 2;
          break;
        case 'news':
          _initialTabIndex = 3;
          break;
      }
    }
    
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _initialTabIndex,
    );
    
    _loadData();
  }

  void _loadData() {
    final cubit = context.read<HomeCubit>();
    final state = cubit.state;
    
    // Load news for the news tab
    context.read<NewsCubit>().loadNews();
    
    // Faqat ma'lumotlar yo'q bo'lsa yuklaymiz
    if (state is! HomeSuccess) {
      cubit.getGoodsList();
      cubit.getPopularGoodsList();
      cubit.getSaleGoodsList();
      return;
    }
    
    // Agar state HomeSuccess bo'lsa, faqat bo'sh bo'lgan ma'lumotlarni yuklaymiz
    if (state.goods == null) {
      cubit.getGoodsList();
    }
    if (state.popularGoods == null) {
      cubit.getPopularGoodsList();
    }
    if (state.saleGoods == null) {
      cubit.getSaleGoodsList();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<HomeCubit>().refresh();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        final cubit = context.read<HomeCubit>();
        final state = cubit.state;
        
        if (state is HomeSuccess) {
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
            default:
              return false; // tab 3 is News — no pagination for it here
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

          if (hasMore && !isLoadingMore && !(_isLoadingMore[activeType] ?? false)) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title ?? 'home_all_products'.tr()),
        backgroundColor: isDark ? AppColors.bgMainDark : AppColors.bgMain,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.black12,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: PillTabBar(
            controller: _tabController,
            tabs: _tabs,
          ),
        ),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeSuccess) {
            return NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(context, state, 'goods'),
                  _buildTabContent(context, state, 'popularGoods'),
                  _buildTabContent(context, state, 'saleGoods'),
                  // Yangiliklar tab
                  RefreshIndicator(
                    onRefresh: () async => context.read<NewsCubit>().loadNews(),
                    child: const HomeNewsWidget(fullPage: true),
                  ),
                ],
              ),
            );
          }

          if (state is HomeError) {
            return CommonErrorWidget(
              message: state.failure.error,
              onRetry: () => _onRefresh(),
              title: 'error'.tr(),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, HomeSuccess state, String type) {
    dynamic productsData;
    bool isLoading;
    String? error;
    bool hasMore;
    bool isLoadingMore;

    switch (type) {
      case 'goods':
        productsData = state.goods;
        isLoading = state.loadingStates['goods'] == true;
        error = state.errorStates['goods']?.error;
        hasMore = state.hasMore['goods'] ?? false;
        isLoadingMore = state.loadingStates['goodsMore'] == true;
        break;
      case 'popularGoods':
        productsData = state.popularGoods;
        isLoading = state.loadingStates['popularGoods'] == true;
        error = state.errorStates['popularGoods']?.error;
        hasMore = state.hasMore['popularGoods'] ?? false;
        isLoadingMore = state.loadingStates['popularGoodsMore'] == true;
        break;
      case 'saleGoods':
        productsData = state.saleGoods;
        isLoading = state.loadingStates['saleGoods'] == true;
        error = state.errorStates['saleGoods']?.error;
        hasMore = state.hasMore['saleGoods'] ?? false;
        isLoadingMore = state.loadingStates['saleGoodsMore'] == true;
        break;
      default:
        productsData = null;
        isLoading = false;
        error = null;
        hasMore = false;
        isLoadingMore = false;
    }

    // Agar TOP yoki Chegirmalar bo'sh bo'lsa,
    // All Products pageda ham asosiy `goods` dan fallback sifatida foydalanamiz.
    dynamic effectiveProductsData = productsData;
    bool effectiveHasMore = hasMore;
    bool effectiveIsLoadingMore = isLoadingMore;

    if ((type == 'popularGoods' || type == 'saleGoods') &&
        extractProducts(productsData).isEmpty &&
        !isLoading &&
        extractProducts(state.goods).isNotEmpty) {
      effectiveProductsData = state.goods;
      effectiveHasMore = state.hasMore['goods'] ?? false;
      effectiveIsLoadingMore = state.loadingStates['goodsMore'] == true;
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

    void retry() {
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
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ProductsList(
        productsData: effectiveProductsData,
        isLoading: isLoading,
        error: error,
        type: type,
        hasMore: effectiveHasMore,
        isLoadingMore: effectiveIsLoadingMore,
        onRetry: retry,
      ),
    );
  }
}
