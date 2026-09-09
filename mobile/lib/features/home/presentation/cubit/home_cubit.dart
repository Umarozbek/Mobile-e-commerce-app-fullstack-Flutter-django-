import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/banner_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../domain/repository/home_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;

  HomeCubit(this._homeRepository) : super(HomeInitial());

  HomeSuccess _getCurrentState() {
    if (state is HomeSuccess) {
      return state as HomeSuccess;
    }
    return  HomeSuccess();
  }

  // Refresh all data — avvalgi ma'lumotlar saqlanadi, shimmer ko'rsatilmaydi
  Future<void> refresh() async {
    final current = _getCurrentState();
    emit(current.copyWith(
      loadingStates: Map.from(current.loadingStates)
        ..['categories'] = true
        ..['banners'] = true
        ..['goods'] = true
        ..['saleGoods'] = true
        ..['newGoods'] = true
        ..['popularGoods'] = true,
    ));
    await Future.wait([
      getCategories(forceRefresh: true),
      getBanners(forceRefresh: true),
      getGoodsList(clearPrevious: false, forceRefresh: true),
      getPopularGoodsList(forceRefresh: true),
      getSaleGoodsList(forceRefresh: true),
      getNewGoodsList(forceRefresh: true),
    ]);
  }

  Future<void> getCategories({bool forceRefresh = false}) async {
    final currentState = _getCurrentState();
    if (!forceRefresh && currentState.categories != null && currentState.categories!.isNotEmpty) return;

    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['categories'] = true,
      errorStates: Map.from(currentState.errorStates)..['categories'] = null,
    ));

    final response = await _homeRepository.getCategories();

    final updatedState = state is HomeSuccess ? state as HomeSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['categories'] = false,
        errorStates: Map.from(updatedState.errorStates)..['categories'] = l,
      )),
      (r) => emit(updatedState.copyWith(
        categories: r.results,
        loadingStates: Map.from(updatedState.loadingStates)..['categories'] = false,
        errorStates: Map.from(updatedState.errorStates)..['categories'] = null,
        nextUrls: Map.from(updatedState.nextUrls)..['categories'] = r.next,
        hasMore: Map.from(updatedState.hasMore)..['categories'] = r.next != null,
      )),
    );
  }

  Future<void> loadMoreCategories() async {
    final currentState = _getCurrentState();
    final nextUrl = currentState.nextUrls['categories'];
    final isLoadingMore = currentState.loadingStates['categoriesMore'] == true;

    if (nextUrl == null || isLoadingMore) return;

    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['categoriesMore'] = true,
      errorStates: Map.from(currentState.errorStates)..['categoriesMore'] = null,
    ));

    final response = await _homeRepository.getCategoriesNext(nextUrl);

    final updatedState = state is HomeSuccess ? state as HomeSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['categoriesMore'] = false,
        errorStates: Map.from(updatedState.errorStates)..['categoriesMore'] = l,
      )),
      (r) => emit(updatedState.copyWith(
        categories: [...(updatedState.categories ?? []), ...r.results],
        loadingStates: Map.from(updatedState.loadingStates)..['categoriesMore'] = false,
        errorStates: Map.from(updatedState.errorStates)..['categoriesMore'] = null,
        nextUrls: Map.from(updatedState.nextUrls)..['categories'] = r.next,
        hasMore: Map.from(updatedState.hasMore)..['categories'] = r.next != null,
      )),
    );
  }

  Future<void> getBanners({bool forceRefresh = false}) async {
    final currentState = _getCurrentState();
    if (!forceRefresh &&
        currentState.banners != null &&
        currentState.banners is BannerModel &&
        (currentState.banners as BannerModel).results != null &&
        (currentState.banners as BannerModel).results!.isNotEmpty) {
      return;
    }

    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['banners'] = true,
      errorStates: Map.from(currentState.errorStates)..['banners'] = null,
    ));

    final response = await _homeRepository.getBanners();

    final updatedState = state is HomeSuccess ? state as HomeSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['banners'] = false,
        errorStates: Map.from(updatedState.errorStates)..['banners'] = l,
      )),
      (r) => emit(updatedState.copyWith(
        banners: r,
        loadingStates: Map.from(updatedState.loadingStates)..['banners'] = false,
        errorStates: Map.from(updatedState.errorStates)..['banners'] = null,
      )),
    );
  }

  // Generic helper for fetching products
  Future<void> _fetchProducts({
    required String key,
    required Future<Either<Failure, ProductResponse>> Function() fetcher,
    required HomeSuccess Function(HomeSuccess state, ProductResponse data) onUpdate,
    bool clearPrevious = false,
    bool forceRefresh = false,
    List<dynamic>? currentData,
    bool Function(HomeSuccess state)? clearFlagUpdater,
  }) async {
    final currentState = _getCurrentState();
    if (!forceRefresh && !clearPrevious && currentData != null && currentData.isNotEmpty) return;

    // Apply clear logic if needed. Since copyWith takes named args for clearing, 
    // we might need to handle it outside or pass a map. 
    // For simplicity, we assume the caller handles specific clear flags if strictly needed, 
    // or we just reset the data in the state.
    
    // However, existing logic emits `clearGoods: clearPrevious`.
    // We can assume passing `clearPrevious` logic is handled in the specific method or we can try to generalize.
    // Let's implement a cleaner approach: just rely on the emitted state.

    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..[key] = true,
      errorStates: Map.from(currentState.errorStates)..[key] = null,
      nextUrls: Map.from(currentState.nextUrls)..[key] = null,
      hasMore: Map.from(currentState.hasMore)..[key] = false,
      // We can't easily pass "clearGoods: true" here dynamically without a huge switch or map.
      // But typically "clearGoods" meant setting goods to null.
      // We can do that in the specific method if really needed, or just let the new data overwrite it.
    ));

    final response = await fetcher();

    final updatedState = state is HomeSuccess ? state as HomeSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..[key] = false,
        errorStates: Map.from(updatedState.errorStates)..[key] = l,
      )),
      (r) {
        final newState = onUpdate(updatedState, r);
        emit(newState.copyWith(
          loadingStates: Map.from(updatedState.loadingStates)..[key] = false,
          errorStates: Map.from(updatedState.errorStates)..[key] = null,
          nextUrls: Map.from(updatedState.nextUrls)..[key] = r.next,
          hasMore: Map.from(updatedState.hasMore)..[key] = r.next != null,
        ));
      },
    );
  }

  // Generic helper for loading more products
  Future<void> _loadMoreProducts({
    required String key,
    required Future<Either<Failure, ProductResponse>> Function(String url) fetcher,
    required HomeSuccess Function(HomeSuccess state, ProductResponse data) onUpdate,
  }) async {
    final currentState = _getCurrentState();
    final nextUrl = currentState.nextUrls[key];
    final isLoadingMore = currentState.loadingStates['${key}More'] == true;

    if (nextUrl == null || isLoadingMore) return;

    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['${key}More'] = true,
      errorStates: Map.from(currentState.errorStates)..['${key}More'] = null,
    ));

    final response = await fetcher(nextUrl);

    final updatedState = state is HomeSuccess ? state as HomeSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['${key}More'] = false,
        errorStates: Map.from(updatedState.errorStates)..['${key}More'] = l,
      )),
      (r) {
        final newState = onUpdate(updatedState, r);
        emit(newState.copyWith(
          loadingStates: Map.from(updatedState.loadingStates)..['${key}More'] = false,
          errorStates: Map.from(updatedState.errorStates)..['${key}More'] = null,
          nextUrls: Map.from(updatedState.nextUrls)..[key] = r.next,
          hasMore: Map.from(updatedState.hasMore)..[key] = r.next != null,
        ));
      },
    );
  }

  Future<void> getGoodsList({bool clearPrevious = false, bool forceRefresh = false}) async {
    if (clearPrevious) {
        emit(_getCurrentState().copyWith(clearGoods: true));
    }
    await _fetchProducts(
      key: 'goods',
      fetcher: () => _homeRepository.getGoodsList(),
      currentData: _getCurrentState().goods,
      forceRefresh: forceRefresh,
      clearPrevious: clearPrevious,
      onUpdate: (state, r) => state.copyWith(goods: r.results),
    );
  }

  Future<void> loadMoreGoods() async {
    await _loadMoreProducts(
      key: 'goods',
      fetcher: (url) => _homeRepository.getGoodsListNext(url),
      onUpdate: (state, r) => state.copyWith(
        goods: [...(state.goods as List? ?? []), ...r.results ?? []],
      ),
    );
  }

  Future<void> getSaleGoodsList({bool forceRefresh = false}) async {
    await _fetchProducts(
      key: 'saleGoods',
      fetcher: () => _homeRepository.getSaleGoodsList(),
      currentData: _getCurrentState().saleGoods,
      forceRefresh: forceRefresh,
      onUpdate: (state, r) => state.copyWith(saleGoods: r.results),
    );
  }

  Future<void> loadMoreSaleGoods() async {
    await _loadMoreProducts(
      key: 'saleGoods',
      fetcher: (url) => _homeRepository.getSaleGoodsListNext(url),
      onUpdate: (state, r) => state.copyWith(
        saleGoods: [...(state.saleGoods as List? ?? []), ...r.results ?? []],
      ),
    );
  }

  Future<void> getNewGoodsList({bool forceRefresh = false}) async {
    await _fetchProducts(
      key: 'newGoods',
      fetcher: () => _homeRepository.getNewGoodsList(),
      currentData: _getCurrentState().newGoods,
      forceRefresh: forceRefresh,
      onUpdate: (state, r) => state.copyWith(newGoods: r.results),
    );
  }

  Future<void> loadMoreNewGoods() async {
    await _loadMoreProducts(
      key: 'newGoods',
      fetcher: (url) => _homeRepository.getNewGoodsListNext(url),
      onUpdate: (state, r) => state.copyWith(
        newGoods: [...(state.newGoods as List? ?? []), ...r.results ?? []],
      ),
    );
  }

  Future<void> getPopularGoodsList({bool forceRefresh = false}) async {
    await _fetchProducts(
      key: 'popularGoods',
      fetcher: () => _homeRepository.getPopularGoodsList(),
      currentData: _getCurrentState().popularGoods,
      forceRefresh: forceRefresh,
      onUpdate: (state, r) => state.copyWith(popularGoods: r.results),
    );
  }

  Future<void> loadMorePopularGoods() async {
    await _loadMoreProducts(
      key: 'popularGoods',
      fetcher: (url) => _homeRepository.getPopularGoodsListNext(url),
      onUpdate: (state, r) => state.copyWith(
        popularGoods: [...(state.popularGoods as List? ?? []), ...r.results ?? []],
      ),
    );
  }

  Future<void> getNewsList() async {
    final currentState = _getCurrentState();
    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['news'] = true,
      errorStates: Map.from(currentState.errorStates)..['news'] = null,
    ));

    final response = await _homeRepository.getNewsList();

    final updatedState = state is HomeSuccess ? state as HomeSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['news'] = false,
        errorStates: Map.from(updatedState.errorStates)..['news'] = l,
      )),
      (r) => emit(updatedState.copyWith(
        news: r,
        loadingStates: Map.from(updatedState.loadingStates)..['news'] = false,
        errorStates: Map.from(updatedState.errorStates)..['news'] = null,
      )),
    );
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(HomeInitial());
}
