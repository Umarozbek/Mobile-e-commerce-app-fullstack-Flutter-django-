import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../home/data/models/product_model.dart';
import '../../data/models/favorite_model.dart';
import '../../domain/repository/favourites_repository.dart';

part 'favourites_state.dart';

class FavouritesCubit extends Cubit<FavouritesState> {
  final FavouritesRepository _favouritesRepository;

  FavouritesCubit(this._favouritesRepository) : super(FavouritesInitial());

  // ── Yagona manba: favourite ID lar to'plami ──
  Set<int> _favouriteIds = {};
  List<ProductModel> _favouriteProducts = [];
  int _version = 0;
  bool _isListLoaded = false;

  // ── Public getters ──

  bool isFavourite(int productId) => _favouriteIds.contains(productId);

  List<ProductModel> get favouriteProducts => List.unmodifiable(_favouriteProducts);

  // ── Yangi state emit qilish (version++ bilan har doim noyob) ──
  void _emitSuccess() {
    _version++;
    emit(FavouritesSuccess(
      favouriteIds: Set.from(_favouriteIds),
      favouriteProducts: List.from(_favouriteProducts),
      isListLoaded: _isListLoaded,
      version: _version,
    ));
  }

  // ── API dan ro'yxat olish ──
  Future<void> getFavouritesList() async {
    // Ma'lumot bo'lmasa loading ko'rsatish
    if (!_isListLoaded && _favouriteIds.isEmpty) {
      emit(const FavouritesLoading(type: 'list'));
    }

    final response = await _favouritesRepository.getFavouritesList();

    response.fold(
      (failure) {
        // Xatolikda mavjud ma'lumotni saqlash
        if (_isListLoaded) {
          _emitSuccess();
        } else {
          emit(FavouritesError(failure: failure, type: 'list'));
        }
      },
      (favoriteResponse) {
        final products = _parseFavourites(favoriteResponse);

        // API dan kelgan ID larni saqlash
        final apiIds = products
            .map((p) => p.effectiveId)
            .where((id) => id > 0)
            .toSet();

        _favouriteIds
          ..clear()
          ..addAll(apiIds);

        _favouriteProducts
          ..clear()
          ..addAll(products);

        _isListLoaded = true;
        _emitSuccess();
      },
    );
  }

  // ── Sevimliga qo'shish (optimistic) ──
  Future<void> addToFavourites({required int productId, ProductModel? product}) async {
    if (productId <= 0) return;

    // 1. Darhol UI ni yangilash
    _favouriteIds.add(productId);
    if (product != null && !_favouriteProducts.any((p) => p.effectiveId == productId)) {
      _favouriteProducts.add(product);
    }
    _emitSuccess();

    // 2. API ga yuborish (background)
    final response = await _favouritesRepository.addToFavourites(productId: productId);

    response.fold(
      (failure) {
        // Xatolikda qaytarish
        _favouriteIds.remove(productId);
        _favouriteProducts.removeWhere((p) => p.effectiveId == productId);
        _emitSuccess();
      },
      (_) {
        // Muvaffaqiyat - hech narsa qilish kerak emas
      },
    );
  }

  // ── Sevimlilardan olib tashlash (optimistic) ──
  Future<void> removeFromFavourites({required int productId}) async {
    if (productId <= 0) return;

    // Qaytarish uchun saqlash
    final removedProduct = _favouriteProducts
        .where((p) => p.effectiveId == productId)
        .firstOrNull;

    // 1. Darhol UI ni yangilash
    _favouriteIds.remove(productId);
    _favouriteProducts.removeWhere((p) => p.effectiveId == productId);
    _emitSuccess();

    // 2. API ga yuborish (background)
    final response = await _favouritesRepository.removeFromFavourites(productId: productId);

    response.fold(
      (failure) {
        // Xatolikda qaytarish
        _favouriteIds.add(productId);
        if (removedProduct != null) {
          _favouriteProducts.add(removedProduct);
        }
        _emitSuccess();
      },
      (_) {
        // Muvaffaqiyat - hech narsa qilish kerak emas
      },
    );
  }

  // ── API javobini ProductModel ga aylantirish (yangi format: names, prices, images) ──
  List<ProductModel> _parseFavourites(FavoriteResponse? data) {
    if (data?.results == null) return [];

    return data!.results!.map((item) {
      final dto = item.product;
      if (dto == null || dto.id == null) return null;

      final hasPrices = dto.prices != null;
      final priceVal = hasPrices
          ? (dto.prices!['price'] is num
              ? (dto.prices!['price'] as num).toDouble()
              : double.tryParse(dto.prices!['price']?.toString() ?? '') ?? 0.0)
          : 0.0;
      final discountPriceVal = hasPrices
          ? (dto.prices!['discount_price'] is num
              ? (dto.prices!['discount_price'] as num).toDouble()
              : double.tryParse(dto.prices!['discount_price']?.toString() ?? '') ?? 0.0)
          : 0.0;
      final discountPercent = hasPrices
          ? (dto.prices!['discount_percent'] is num
              ? (dto.prices!['discount_percent'] as num).toInt()
              : int.tryParse(dto.prices!['discount_percent']?.toString() ?? '') ?? 0)
          : 0;

      String? newPrice;
      String? oldPrice;

      // Yangi API: discount_price – eski narx, price – yangi narx
      if (discountPriceVal > 0 && priceVal > 0) {
        newPrice = priceVal.toString();
        oldPrice = discountPriceVal.toString();
      }
      // Eski API: discount_percent bo'yicha eski narxni hisoblash
      else if (discountPercent > 0 && priceVal > 0) {
        newPrice = priceVal.toString();
        oldPrice = (priceVal / (1 - discountPercent / 100)).toStringAsFixed(0);
      } else if (priceVal > 0) {
        newPrice = priceVal.toString();
      }
      final b2bPriceVal = dto.prices != null && dto.prices!['b2b_price'] != null
          ? (dto.prices!['b2b_price'] is num
              ? (dto.prices!['b2b_price'] as num).toDouble()
              : double.tryParse(dto.prices!['b2b_price']?.toString() ?? ''))
          : null;

      final images = dto.images
          ?.map((url) => ProductImage(image: url))
          .toList();

      final details = ProductDetails(
        id: dto.id,
        descriptions: dto.descriptions,
        productType: dto.productType,
        newPrice: newPrice,
        oldPrice: oldPrice?.isNotEmpty == true ? oldPrice : null,
        price: priceVal,
        b2bPrice: b2bPriceVal,
        images: images,
        goods: null,
      );

      return ProductModel(
        id: dto.id,
        product: details,
        isFavorite: true,
        names: dto.names,
        name: dto.names?.uz ?? dto.names?.en ?? dto.names?.ru ?? dto.names?.kr,
        nameUz: dto.names?.uz,
        nameEn: dto.names?.en,
        nameRu: dto.names?.ru,
        nameKr: dto.names?.kr,
      );
    }).whereType<ProductModel>().toList();
  }

  /// Logout paytida state tozalanadi
  void reset() {
    _favouriteIds = {};
    _favouriteProducts = [];
    _isListLoaded = false;
    emit(FavouritesInitial());
  }
}
