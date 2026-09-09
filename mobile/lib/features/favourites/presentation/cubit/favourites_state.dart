part of 'favourites_cubit.dart';

sealed class FavouritesState extends Equatable {
  const FavouritesState();

  @override
  List<Object> get props => [];
}

final class FavouritesInitial extends FavouritesState {}

final class FavouritesLoading extends FavouritesState {
  final String? type;
  const FavouritesLoading({this.type});
  
  @override
  List<Object> get props => [type ?? ''];
}

final class FavouritesSuccess extends FavouritesState {
  final Set<int> favouriteIds;
  final List<ProductModel> favouriteProducts;
  final bool isListLoaded;
  final int version; // Har bir emit noyob bo'lishi uchun

  const FavouritesSuccess({
    this.favouriteIds = const {},
    this.favouriteProducts = const [],
    this.isListLoaded = false,
    this.version = 0,
  });

  bool isFavourite(int productId) {
    return favouriteIds.contains(productId);
  }

  FavouritesSuccess copyWith({
    Set<int>? favouriteIds,
    List<ProductModel>? favouriteProducts,
    bool? isListLoaded,
    int? version,
  }) {
    return FavouritesSuccess(
      favouriteIds: favouriteIds ?? this.favouriteIds,
      favouriteProducts: favouriteProducts ?? this.favouriteProducts,
      isListLoaded: isListLoaded ?? this.isListLoaded,
      version: version ?? this.version,
    );
  }

  @override
  List<Object> get props => [favouriteIds, favouriteProducts, isListLoaded, version];
}

final class FavouritesError extends FavouritesState {
  final Failure failure;
  final String? type;
  
  const FavouritesError({required this.failure, this.type});
  
  @override
  List<Object> get props => [failure, type ?? ''];
}
