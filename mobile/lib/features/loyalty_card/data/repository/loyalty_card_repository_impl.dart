
import 'package:dartz/dartz.dart';

import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/loyalty_card_repository.dart';
import '../models/loyalty_card_model.dart';
import '../models/loyalty_history_model.dart';

class LoyaltyCardRepositoryImpl implements LoyaltyCardRepository {
  final ApiClient _apiClient;

  LoyaltyCardRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, LoyaltyCardModel>> getBonusList() async {
    final response = await _apiClient.get(
      MainUrls.myLoyaltyCard,
      isHeader: true,
    );
    if (response.isSuccess) {
      if (response.response != null &&
          response.response is Map<String, dynamic>) {
        try {
          final model = LoyaltyCardModel.fromJson(response.response);
          return Right(model);
        } catch (e) {
          logger.e("Parsing Error: $e");
          return Left(Failure(error: 'Data parsing error: $e'));
        }
      }
      return Left(Failure(error: 'Invalid data format'));
    }
    return Left(
      Failure(error: response.response.toString(), statusCode: response.code),
    );
  }
  @override
  Future<Either<Failure, LoyaltyHistoryResponse>> getLoyaltyHistory() async {
final response = await _apiClient.get(
  MainUrls.loyaltyHistory,
      isHeader: true,
    );
    if (response.isSuccess) {
      if (response.response != null &&
          response.response is Map<String, dynamic>) {
        try {
          final model = LoyaltyHistoryResponse.fromJson(response.response);
          return Right(model);
        } catch (e) {
          logger.e("Parsing Error: $e");
          return Left(Failure(error: 'Data parsing error: $e'));
        }
      }
      return Left(Failure(error: 'Invalid data format'));
    }
    return Left(
      Failure(error: response.response.toString(), statusCode: response.code),
    );
  }
}
