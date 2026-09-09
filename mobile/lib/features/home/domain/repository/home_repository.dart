
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/banner_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';

abstract class HomeRepository {
  Future<Either<Failure, CategoryListResponse>> getCategories();
  Future<Either<Failure, CategoryListResponse>> getCategoriesNext(String nextUrl);
  Future<Either<Failure, BannerModel>> getBanners();
  Future<Either<Failure, ProductResponse>> getGoodsList();
  Future<Either<Failure, ProductResponse>> getSaleGoodsList();
  Future<Either<Failure, ProductResponse>> getNewGoodsList();
  Future<Either<Failure, ProductResponse>> getPopularGoodsList();
  Future<Either<Failure, dynamic>> getNewsList();
  
  // Pagination methods
  Future<Either<Failure, ProductResponse>> getGoodsListNext(String nextUrl);
  Future<Either<Failure, ProductResponse>> getSaleGoodsListNext(String nextUrl);
  Future<Either<Failure, ProductResponse>> getNewGoodsListNext(String nextUrl);
  Future<Either<Failure, ProductResponse>> getPopularGoodsListNext(String nextUrl);
  
  // Category filtering
  Future<Either<Failure, ProductResponse>> getProductsByCategory(int categoryId, {int page = 1, int pageSize = 20});
  Future<Either<Failure, ProductResponse>> getProductsByCategoryNext(String nextUrl);
}
