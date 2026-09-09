
import 'package:dartz/dartz.dart';

import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, dynamic>> getProfile() async {
    final response = await _apiClient.get(MainUrls.information, isHeader: true);
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
  Future<Either<Failure, bool>> updateProfile({required Map<String, dynamic> data}) async {
    final response = await _apiClient.put(
      MainUrls.profileCreate,
      body: data,
      isHeader: true
    );
    if (response.isSuccess) {
      return Right(true);
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, bool>> deleteProfile() async {
    final response = await _apiClient.delete(MainUrls.profileDelete);
    if (response.isSuccess) {
      return Right(true);
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, dynamic>> getLocations() async {
    final response = await _apiClient.get(MainUrls.locations);
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
  Future<Either<Failure, dynamic>> createLocation({required Map<String, dynamic> data}) async {
    final response = await _apiClient.post(
      MainUrls.locationsCreate,
      body: data,
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

