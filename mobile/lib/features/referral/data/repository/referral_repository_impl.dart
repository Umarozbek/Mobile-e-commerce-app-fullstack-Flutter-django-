
import 'package:dartz/dartz.dart';

import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/referral_repository.dart';
import '../models/referral_model.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final ApiClient _apiClient;

  ReferralRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, ReferralModel>> getReferralCode() async {
    final response = await _apiClient.get(MainUrls.myBonus);

    if (response.isSuccess) {
      try {
        final data = response.response;
        final map = data is Map<String, dynamic>
            ? data
            : (data is Map ? Map<String, dynamic>.from(data as Map) : null);
        if (map != null) {
          final referralModel = ReferralModel.fromJson(map);
          return Right(referralModel);
        }
      } catch (e) {
        logger.e("Referral Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(
      Failure(error: response.response.toString(), statusCode: response.code),
    );
  }

  @override
  Future<Either<Failure, bool>> enterReferralCode({
    required String code,
  }) async {
    // customer/enter-referral-code/ - B2B va oddiy foydalanuvchilar uchun
    final response = await _apiClient.post(
      MainUrls.enterReferralCode,
      body: {'referral_code': code},
    );

    if (response.isSuccess) {
      return const Right(true);
    }
    return Left(
      Failure(error: response.response.toString(), statusCode: response.code),
    );
  }
}

