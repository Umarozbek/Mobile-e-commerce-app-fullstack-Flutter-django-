
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/common_error_widget.dart';
import '../../data/models/category_model.dart';
import '../cubit/category_products_cubit.dart';
import '../widget/products_list.dart';
import '../widget/product_shimmer.dart';

class CategoryProductsPage extends StatefulWidget {
  final CategoryModel category;

  const CategoryProductsPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CategoryProductsCubit>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<CategoryProductsCubit>().getProducts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.category.nameUz ?? widget.category.name ?? 'categories'.tr(),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
        builder: (context, state) {
          if (state is CategoryProductsLoading) {
            return const ProductShimmer();
          }

          if (state is CategoryProductsError) {
            return CommonErrorWidget(
              message: state.message,
              onRetry: () => context.read<CategoryProductsCubit>().getProducts(refresh: true),
              title: 'error'.tr(),
            );
          }

          if (state is CategoryProductsSuccess) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ProductsList(
                productsData: state.products,
                isLoading: false,
                error: state.error,
                type: 'category_${widget.category.id}',
                fromHome: false,
                hasMore: state.products?.next != null,
                isLoadingMore: state.isLoadingMore,
                onRetry: () => context.read<CategoryProductsCubit>().getProducts(refresh: true),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
