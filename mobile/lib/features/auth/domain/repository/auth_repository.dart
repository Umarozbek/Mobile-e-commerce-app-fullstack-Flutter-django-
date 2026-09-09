import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/register_result.dart';

abstract class AuthRepository {
  Future<Either<Failure, bool>> login({
    required String number,
    required String password,
  });

  /// Eski (GetStorage dagi) tokenni API ga yuborib yangi JWT oladi va SecureStorage ga yozadi.
  Future<Either<Failure, bool>> updateToken(String oldToken);

  Future<Either<Failure, RegisterResult>> register({
    required String number,
    required String fullName,
    String? referralCode,
  });

  Future<Either<Failure, bool>> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<Either<Failure, bool>> setPassword({
    required String phone,
    required String password,
  });
}
