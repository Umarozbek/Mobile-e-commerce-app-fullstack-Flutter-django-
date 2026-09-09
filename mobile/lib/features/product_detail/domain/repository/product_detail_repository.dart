
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class ProductDetailRepository {
  Future<Either<Failure, dynamic>> getProductDetail({required int productId});
  Future<Either<Failure, dynamic>> getGoodVariants({required int productId});
  Future<Either<Failure, dynamic>> getTicketVariants({required int productId});
  Future<Either<Failure, dynamic>> getPhoneVariants({required int productId});
}

