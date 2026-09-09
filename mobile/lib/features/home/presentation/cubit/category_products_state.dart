part of 'category_products_cubit.dart';

abstract class CategoryProductsState extends Equatable {
  const CategoryProductsState();
  
  @override
  List<Object?> get props => [];
}

class CategoryProductsInitial extends CategoryProductsState {}

class CategoryProductsLoading extends CategoryProductsState {}

class CategoryProductsSuccess extends CategoryProductsState {
  final ProductResponse? products;
  final bool isLoadingMore;
  final String? error;

  const CategoryProductsSuccess({
    this.products,
    this.isLoadingMore = false,
    this.error,
  });

  @override
  List<Object?> get props => [products, isLoadingMore, error];

  CategoryProductsSuccess copyWith({
    ProductResponse? products,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return CategoryProductsSuccess(
      products: products ?? this.products,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CategoryProductsError extends CategoryProductsState {
  final String message;

  const CategoryProductsError(this.message);

  @override
  List<Object?> get props => [message];
}
