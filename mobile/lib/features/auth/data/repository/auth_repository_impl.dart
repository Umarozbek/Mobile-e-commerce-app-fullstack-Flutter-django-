
import 'dart:convert';
import 'package:dartz/dartz.dart';

import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/service/secure_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/register_result.dart';
import '../../domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, bool>> login({
    required String number,
    required String password,
  }) async {
    final fcmToken = await SecureStorage().read(key: 'fcm_token');
    final response = await _apiClient.post(
      MainUrls.login,
      body: {
        "password": password,
        'phone_number': number,
        "device_token": fcmToken ?? "",
      },
      isHeader: false, // Login endpoint token kerak emas
    );
    if (response.isSuccess) {
      try {
        // final newAccessToken = response.response['token'].toString();
        final newAccessToken = response.response['access'].toString();
        // final newRefreshToken = response.response['refresh'].toString();
        final fullName = response.response['full_name'].toString();
        await SecureStorage().write(key: "accessToken", value: newAccessToken);
        // await SecureStorage().write(key: "refreshToken", value: newRefreshToken);
        await SecureStorage().write(key: "full_name", value: fullName);
        await SecureStorage().write(key: "phone_number", value: number);
        return Right(true);
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(
            error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    final error = response.response;
    return Left(
      Failure(
          error: error is Map || error is List
              ? jsonEncode(error)
              : error.toString(),
          statusCode: response.code),
    );
  }

  @override
  Future<Either<Failure, bool>> updateToken(String oldToken) async {
    if (oldToken.isEmpty) return Left(Failure(error: "Old token empty", statusCode: 400));
    final response = await _apiClient.post(
      MainUrls.updateToken,
      body: {
        "token": oldToken
      },
      isHeader: false,
      // customHeaders: {"Authorization": "Bearer $oldToken"},
    );
    if (response.isSuccess) {
      try {
        final newAccessToken = response.response['access']?.toString() ?? response.response['access_token']?.toString();
        final newRefreshToken = response.response['refresh']?.toString() ?? response.response['refresh_token']?.toString();
        if (newAccessToken == null || newAccessToken.isEmpty) {
          return Left(Failure(error: "Token not in response", statusCode: response.code));
        }
        await SecureStorage().write(key: "accessToken", value: newAccessToken);
        await SecureStorage().write(key: "refreshToken", value: newRefreshToken??"");
        final fullName = response.response['full_name']?.toString();
        final phoneNumber = response.response['phone_number']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          await SecureStorage().write(key: "full_name", value: fullName);
          await SecureStorage().write(key: "phone_number", value: phoneNumber??"");
        }
        return Right(true);
      } catch (e) {
        logger.e("updateToken parsing error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    final error = response.response;
    return Left(
      Failure(
        error: error is Map || error is List ? jsonEncode(error) : error.toString(),
        statusCode: response.code,
      ),
    );
  }

  @override
  Future<Either<Failure, RegisterResult>> register({
    required String number,
    required String fullName,
    String? referralCode,
  }) async {
    final body = <String, dynamic>{
      'phone_number': number,
      'full_name': fullName,
    };
    if (referralCode != null && referralCode.trim().isNotEmpty) {
      print(referralCode);
      body['referral_code'] = referralCode.trim();
    }
    final response = await _apiClient.post(
      MainUrls.register,
      body: body,
      isHeader: false, // Register endpoint token kerak emas
    );
    if (response.isSuccess) {
      try {
        if (response.response is Map) {
          final responseMap = response.response as Map;
          final token =
              responseMap['token']?.toString() ??
              responseMap['verification_token']?.toString() ??
              responseMap['otp_token']?.toString();
          final otpDebug = responseMap['otp_debug']?.toString();
          final referralBonusGiven = responseMap['referral_bonus_given'] == true;
          return Right(RegisterResult(token: token, otpDebug: otpDebug, referralBonusGiven: referralBonusGiven));
        }
        return Right(const RegisterResult());
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(
            error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    final error = response.response;
    return Left(
      Failure(
          error: error is Map || error is List
              ? jsonEncode(error)
              : error.toString(),
          statusCode: response.code),
    );
  }

  @override
  Future<Either<Failure, bool>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      MainUrls.verifyOtp,
      body: {"otp": otp, 'phone_number': phone},
      isHeader: false, // Verify OTP endpoint token kerak emas
    );
    if (response.isSuccess) {
      return Right(true);
    }
    final error = response.response;
    return Left(
      Failure(
          error: error is Map || error is List
              ? jsonEncode(error)
              : error.toString(),
          statusCode: response.code),
    );
  }

  @override
  Future<Either<Failure, bool>> setPassword({
    required String phone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      MainUrls.setPassword,
      body: {"new_password": password, "phone_number": phone},
      isHeader: false, // Set Password endpoint token kerak emas
    );
    if (response.isSuccess) {
      return Right(true);
    }
    final error = response.response;
    return Left(
      Failure(
          error: error is Map || error is List
              ? jsonEncode(error)
              : error.toString(),
          statusCode: response.code),
    );
  }
}
