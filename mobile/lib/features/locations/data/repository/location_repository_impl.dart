import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repository/location_repository.dart';
import '../models/location_model.dart';
import '../../../../core/utils/logger.dart';

class LocationRepositoryImpl implements LocationRepository {
  final ApiClient _apiClient;

  LocationRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, LocationModel>> createLocation({
    required String address,
    required bool active,
  }) async {
    final response = await _apiClient.post(
      'customer/location/create/',
      body: {'address': address, 'active': active},
    );

    if (response.isSuccess) {
      try {
        return Right(LocationModel.fromJson(response.response));
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }

    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, List<LocationModel>>> getLocations() async {
    final response = await _apiClient.get(
      'customer/location/list/',
    );

    if (response.isSuccess) {
      try {
        final List<dynamic> results = response.response['results'];
        return Right(results.map((e) => LocationModel.fromJson(e)).toList());
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }

    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, void>> deleteLocation(int id) async {
    final response = await _apiClient.delete(
      'customer/location/$id/retrieve/',
    );

    if (response.isSuccess) {
      return const Right(null);
    }

    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }


  @override
  Future<Either<Failure, LocationModel>> updateLocation({
    required int id,
    required String address,
    required bool active,
  }) async {
    final response = await _apiClient.patch(
      'customer/location/$id/retrieve/',
      body: {'address': address, 'active': active},
    );

    if (response.isSuccess) {
      try {
        return Right(LocationModel.fromJson(response.response));
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }

    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }
}
