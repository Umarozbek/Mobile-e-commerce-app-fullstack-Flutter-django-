import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/cart_repository.dart';
import '../models/cart_order_model.dart';

class CartRepositoryImpl implements CartRepository {
  final ApiClient _apiClient;

  CartRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, CartOrderResponse>> getCart() async {
    final response = await _apiClient.get(MainUrls.cartOrderList);
    if (response.isSuccess) {
      try {
        var data = response.response;

        if (data is String) {
          try {

            data = jsonDecode(data); // Requires import 'dart:convert'
          } catch (e) {
            // Keep original data if decoding fails
          }
        }

        // Parse summary list
        if (data is List) {
           final list = data;
           final results = list.map((e) => CartOrderModel.fromJson(e)).toList();
           final summaryResponse = CartOrderResponse(
             count: results.length,
             results: results,
           );
           return Right(summaryResponse);
        } else {
           final summaryResponse = CartOrderResponse.fromJson(data);
           return Right(summaryResponse);
        }
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: e.toString(), statusCode: 500));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, void>> deleteCartItem({required int orderId, required int productId}) async {
    final response = await _apiClient.post(
      'merchant/cart/remove-item/',
      body: {
        'order_id': orderId,
        'product_id': productId,
      },
    );
    if (response.isSuccess) {
      return const Right(null);
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, void>> addItemToCart({required int productId, required int quantity}) async {
    final response = await _apiClient.post(
      MainUrls.merchantCartManage,
      body: {
        'quantity': quantity,
        'product': productId,
      },
    );
    if (response.isSuccess) {
      return const Right(null);
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, void>> updateQuantity({required int productId, required int quantity,required int orderId}) async {
    final response = await _apiClient.post(
      MainUrls.merchantCartUpdateQuantity,
      body: {
        "order_id": orderId,
        "product_id": productId,
        "quantity": quantity
      },
    );
    if (response.isSuccess) {
      return const Right(null);
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }
}
