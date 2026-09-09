
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class SearchRepository {
  Future<Either<Failure, dynamic>> searchProducts({required String query});
  Future<Either<Failure, dynamic>> searchProductsNext({required String nextUrl});
}
