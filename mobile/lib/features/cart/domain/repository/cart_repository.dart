
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/cart_order_model.dart';

abstract class CartRepository {
  Future<Either<Failure, CartOrderResponse>> getCart();
  Future<Either<Failure, void>> deleteCartItem({required int orderId, required int productId});
  Future<Either<Failure, void>> addItemToCart({required int productId, required int quantity});
  Future<Either<Failure, void>> updateQuantity({required int productId, required int quantity, required int orderId});
}
