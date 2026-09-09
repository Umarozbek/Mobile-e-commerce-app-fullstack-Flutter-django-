import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

import '../../data/models/product_model.dart';
import '../../domain/repository/home_repository.dart';

part 'category_products_state.dart';

class CategoryProductsCubit extends Cubit<CategoryProductsState> {
  final HomeRepository _homeRepository;
  final int categoryId;

  CategoryProductsCubit({
    required HomeRepository homeRepository,
    required this.categoryId,
  })  : _homeRepository = homeRepository,
        super(CategoryProductsInitial());

  Future<void> getProducts({bool refresh = false}) async {
    if (refresh) {
      emit(CategoryProductsLoading());
    } else if (state is CategoryProductsInitial) {
      emit(CategoryProductsLoading());
    }

    final response = await _homeRepository.getProductsByCategory(categoryId);

    if (isClosed) return;
    response.fold(
      (failure) => emit(CategoryProductsError(failure.error)),
      (productResponse) => emit(
        CategoryProductsSuccess(products: productResponse),
      ),
    );
  }

  Future<void> loadMore() async {
    if (state is! CategoryProductsSuccess) return;

    final currentState = state as CategoryProductsSuccess;
    final products = currentState.products;

    if (products == null || products.next == null) return;
    if (currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true, clearError: true));

    final response =
        await _homeRepository.getProductsByCategoryNext(products.next!);

    if (isClosed) return;

    response.fold(
      (failure) {
        emit(currentState.copyWith(
          isLoadingMore: false,
          error: failure.error,
        ));
      },
      (newProducts) {
        final currentProducts = products.results ?? [];
        final updatedProducts = ProductResponse(
          count: newProducts.count,
          next: newProducts.next,
          previous: newProducts.previous,
          results: [...currentProducts, ...?newProducts.results],
        );

        emit(currentState.copyWith(
          products: updatedProducts,
          isLoadingMore: false,
          clearError: true,
        ));
      },
    );
  }
}
