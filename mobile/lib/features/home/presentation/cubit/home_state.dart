part of 'home_cubit.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {
  final String? type;
  HomeLoading({this.type});
  
  @override
  List<Object> get props => [type ?? ''];
}

final class HomeSuccess extends HomeState {
  final List<CategoryModel>? categories;
  final dynamic banners;
  final dynamic goods;
  final dynamic saleGoods;
  final dynamic newGoods;
  final dynamic popularGoods;
  final dynamic news;
  
  final Map<String, bool> loadingStates;
  final Map<String, Failure?> errorStates;
  final Map<String, String?> nextUrls; // Pagination next URLs
  final Map<String, bool> hasMore; // Has more pages flag
  
  HomeSuccess({
    this.categories,
    this.banners,
    this.goods,
    this.saleGoods,
    this.newGoods,
    this.popularGoods,
    this.news,
    Map<String, bool>? loadingStates,
    Map<String, Failure?>? errorStates,
    Map<String, String?>? nextUrls,
    Map<String, bool>? hasMore,
  }) : loadingStates = loadingStates ?? {},
       errorStates = errorStates ?? {},
       nextUrls = nextUrls ?? {},
       hasMore = hasMore ?? {};
  
  HomeSuccess copyWith({
    List<CategoryModel>? categories,
    dynamic banners,
    dynamic goods,
    dynamic saleGoods,
    dynamic newGoods,
    dynamic popularGoods,
    dynamic news,
    Map<String, bool>? loadingStates,
    Map<String, Failure?>? errorStates,
    Map<String, String?>? nextUrls,
    Map<String, bool>? hasMore,
    bool? clearCategories,
    bool? clearBanners,
    bool? clearGoods,
    bool? clearSaleGoods,
    bool? clearNewGoods,
    bool? clearPopularGoods,
    bool? clearNews,
  }) {
    return HomeSuccess(
      categories: clearCategories == true ? null : (categories ?? this.categories),
      banners: clearBanners == true ? null : (banners ?? this.banners),
      goods: clearGoods == true ? null : (goods ?? this.goods),
      saleGoods: clearSaleGoods == true ? null : (saleGoods ?? this.saleGoods),
      newGoods: clearNewGoods == true ? null : (newGoods ?? this.newGoods),
      popularGoods: clearPopularGoods == true ? null : (popularGoods ?? this.popularGoods),
      news: clearNews == true ? null : (news ?? this.news),
      loadingStates: loadingStates ?? Map.from(this.loadingStates),
      errorStates: errorStates ?? Map.from(this.errorStates),
      nextUrls: nextUrls ?? Map.from(this.nextUrls),
      hasMore: hasMore ?? Map.from(this.hasMore),
    );
  }
  
  @override
  List<Object> get props => [
    categories ?? '',
    banners ?? '',
    goods ?? '',
    saleGoods ?? '',
    newGoods ?? '',
    popularGoods ?? '',
    news ?? '',
    loadingStates,
    errorStates,
    nextUrls,
    hasMore,
  ];
}

final class HomeError extends HomeState {
  final Failure failure;
  final String? type;
  
  HomeError({required this.failure, this.type});
  
  @override
  List<Object> get props => [failure, type ?? ''];
}
