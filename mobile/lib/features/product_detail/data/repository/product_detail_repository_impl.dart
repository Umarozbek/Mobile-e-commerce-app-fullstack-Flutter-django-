
import 'package:dartz/dartz.dart';

import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/product_detail_repository.dart';

class ProductDetailRepositoryImpl implements ProductDetailRepository {
  final ApiClient _apiClient;

  ProductDetailRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, dynamic>> getProductDetail({required int productId}) async {
    final response = await _apiClient.get(
      MainUrls.goodsList,
      queryParams: {'id': productId},
    );
    if (response.isSuccess) {
      try {
        return Right(response.response);
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, dynamic>> getGoodVariants({required int productId}) async {
    final response = await _apiClient.get(
      MainUrls.goodVariants,
      queryParams: {'product_id': productId},
    );
    if (response.isSuccess) {
      try {
        return Right(response.response);
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, dynamic>> getTicketVariants({required int productId}) async {
    final response = await _apiClient.get(
      MainUrls.ticketVariants,
      queryParams: {'product_id': productId},
    );
    if (response.isSuccess) {
      try {
        return Right(response.response);
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, dynamic>> getPhoneVariants({required int productId}) async {
    final response = await _apiClient.get(
      MainUrls.phoneVariantsVariants,
      queryParams: {'product_id': productId},
    );
    if (response.isSuccess) {
      try {
        return Right(response.response);
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }
}

