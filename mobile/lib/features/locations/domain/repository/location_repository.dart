
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../data/models/location_model.dart';

abstract class LocationRepository {
  Future<Either<Failure, LocationModel>> createLocation({
    required String address,
    required bool active,
  });

  Future<Either<Failure, List<LocationModel>>> getLocations();

  Future<Either<Failure, void>> deleteLocation(int id);

  Future<Either<Failure, LocationModel>> updateLocation({
    required int id,
    required String address,
    required bool active,
  });
}
