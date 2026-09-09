import 'package:dartz/dartz.dart';

import '../../../../core/constans/api_consts.dart';
import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/home_repository.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final ApiClient _apiClient;

  HomeRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, CategoryListResponse>> getCategories() async {
    final response = await _apiClient.get(MainUrls.categoryList);
    if (response.isSuccess) {
      try {
        if (response.response is List) {
          final list = (response.response as List)
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(CategoryListResponse(results: list));
        }
        if (response.response is Map && response.response['results'] != null) {
          return Right(CategoryListResponse.fromJson(
            response.response as Map<String, dynamic>,
          ));
        }
        return Right(CategoryListResponse());
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, CategoryListResponse>> getCategoriesNext(String nextUrl) async {
    final response = await _apiClient.get(nextUrl, anotherLink: true);
    if (response.isSuccess) {
      try {
        if (response.response is Map && response.response['results'] != null) {
          return Right(CategoryListResponse.fromJson(
            response.response as Map<String, dynamic>,
          ));
        }
        return Right(CategoryListResponse());
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, BannerModel>> getBanners() async {
    final response = await _apiClient.get(MainUrls.bannerList);
    if (response.isSuccess) {
      final data = response.response;
      if (data is Map<String, dynamic>) {
        return Right(BannerModel.fromJson(data));
      }
      if (data is Map) {
        return Right(BannerModel.fromJson(Map<String, dynamic>.from(data)));
      }
      return Left(Failure(error: 'Banner response format error', statusCode: response.code));
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  Future<Either<Failure, ProductResponse>> _getProducts(String url, {bool anotherLink = false}) async {
    final response = await _apiClient.get(url, anotherLink: anotherLink);
    if (response.isSuccess) {
      try {
        final data = response.response;
        if (data is Map<String, dynamic>) {
          return Right(ProductResponse.fromJson(data));
        }
        if (data is Map) {
          return Right(ProductResponse.fromJson(Map<String, dynamic>.from(data)));
        }
        return Left(Failure(error: 'Product list format error', statusCode: response.code));
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, ProductResponse>> getGoodsList() =>
      _getProducts('${MainUrls.goodsList}?page=1&page_size=30');

  @override
  Future<Either<Failure, ProductResponse>> getSaleGoodsList() => _getProducts(MainUrls.goodsSaleList);

  @override
  Future<Either<Failure, ProductResponse>> getNewGoodsList() => _getProducts(MainUrls.goodsNewList);

  @override
  Future<Either<Failure, ProductResponse>> getPopularGoodsList() => _getProducts(MainUrls.goodsTopList);

  @override
  Future<Either<Failure, dynamic>> getNewsList() async {
    final response = await _apiClient.get(MainUrls.newsList);
    if (response.isSuccess) {
      return Right(response.response);
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  /// Pagination: nextUrl full bo'lsa ishlatamiz, nisbiy bo'lsa baseUrl qo'shamiz.
  String _resolveNextUrl(String nextUrl) {
    if (nextUrl.startsWith('http')) return nextUrl;
    final base = ApiConsts.baseUrl;
    final path = nextUrl.startsWith('/') ? nextUrl.substring(1) : nextUrl;
    return base.endsWith('/') ? '$base$path' : '$base/$path';
  }

  @override
  Future<Either<Failure, ProductResponse>> getGoodsListNext(String nextUrl) =>
      _getProducts(_resolveNextUrl(nextUrl), anotherLink: true);

  @override
  Future<Either<Failure, ProductResponse>> getSaleGoodsListNext(String nextUrl) => _getProducts(_resolveNextUrl(nextUrl), anotherLink: true);

  @override
  Future<Either<Failure, ProductResponse>> getNewGoodsListNext(String nextUrl) => _getProducts(_resolveNextUrl(nextUrl), anotherLink: true);

  @override
  Future<Either<Failure, ProductResponse>> getPopularGoodsListNext(String nextUrl) => _getProducts(_resolveNextUrl(nextUrl), anotherLink: true);

  @override
  Future<Either<Failure, ProductResponse>> getProductsByCategory(
    int categoryId, {
    int page = 1,
    int pageSize = 30,
  }) {
    final url = '${MainUrls.goodsList}?category=$categoryId&page=$page&page_size=$pageSize';
    return _getProducts(url);
  }

  @override
  Future<Either<Failure, ProductResponse>> getProductsByCategoryNext(String nextUrl) => _getProducts(nextUrl, anotherLink: true);
}
