
import 'package:dartz/dartz.dart';

import '../../../../core/constans/api_consts.dart';
import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../home/data/models/product_model.dart';
import '../../domain/repository/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final ApiClient _apiClient;

  SearchRepositoryImpl(this._apiClient);

  /// Search uchun paginatsiyali mahsulot ro'yxatini olib kelish
  Future<Either<Failure, ProductResponse>> _getSearchProducts(
    String url, {
    bool anotherLink = false,
  }) async {
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
        return Left(Failure(error: 'Search list format error', statusCode: response.code));
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  /// next URL absolyut bo'lmasa, bazaviy URL bilan birlashtiramiz
  String _resolveNextUrl(String nextUrl) {
    if (nextUrl.startsWith('http')) return nextUrl;
    final base = ApiConsts.baseUrl;
    final path = nextUrl.startsWith('/') ? nextUrl.substring(1) : nextUrl;
    return base.endsWith('/') ? '$base$path' : '$base/$path';
  }

  @override
  Future<Either<Failure, dynamic>> searchProducts({required String query}) {
    final url = "${MainUrls.goodsList}?page=1&page_size=30&search=$query";
    return _getSearchProducts(url);
  }

  @override
  Future<Either<Failure, dynamic>> searchProductsNext({required String nextUrl}) {
    final resolved = _resolveNextUrl(nextUrl);
    return _getSearchProducts(resolved, anotherLink: true);
  }
}
