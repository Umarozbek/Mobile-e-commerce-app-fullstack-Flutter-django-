
import 'package:dartz/dartz.dart';

import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/favourites_repository.dart';
import '../models/favorite_model.dart';



class FavouritesRepositoryImpl implements FavouritesRepository {
  final ApiClient _apiClient;

  FavouritesRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, FavoriteResponse>> getFavouritesList() async {
    final response = await _apiClient.get(MainUrls.favoriteList);
    if (response.isSuccess) {
      try {
        return Right(FavoriteResponse.fromJson(response.response));
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(
      Failure(error: response.response.toString(), statusCode: response.code),
    );
  }

  @override
  Future<Either<Failure, bool>> addToFavourites({
    required int productId,
  }) async {
    final response = await _apiClient.post(
      MainUrls.favoriteCreate,
      body: {'product': productId},
    );
    if (response.isSuccess) {
      return Right(true);
    }
    return Left(
      Failure(error: response.response.toString(), statusCode: response.code),
    );
  }

  @override
  Future<Either<Failure, bool>> removeFromFavourites({
    required int productId,
  }) async {
    final response = await _apiClient.delete(
      'customer/favorite/$productId/retrieve/',
    );
    if (response.isSuccess) {
      return Right(true);
    }
    return Left(
      Failure(error: response.response.toString(), statusCode: response.code),
    );
  }
}
