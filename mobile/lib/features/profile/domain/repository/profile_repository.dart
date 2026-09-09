
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class ProfileRepository {
  Future<Either<Failure, dynamic>> getProfile();
  Future<Either<Failure, bool>> updateProfile({required Map<String, dynamic> data});
  Future<Either<Failure, bool>> deleteProfile();
  Future<Either<Failure, dynamic>> getLocations();
  Future<Either<Failure, dynamic>> createLocation({required Map<String, dynamic> data});
}

