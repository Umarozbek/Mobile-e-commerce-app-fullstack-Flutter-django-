
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/favorite_model.dart';

abstract class FavouritesRepository {
  Future<Either<Failure, FavoriteResponse>> getFavouritesList();
  Future<Either<Failure, bool>> addToFavourites({required int productId});
  Future<Either<Failure, bool>> removeFromFavourites({required int productId});
}

