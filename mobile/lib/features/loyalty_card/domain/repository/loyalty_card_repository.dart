
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/loyalty_card_model.dart';
import '../../data/models/loyalty_history_model.dart';



abstract class LoyaltyCardRepository {
  Future<Either<Failure, LoyaltyCardModel>> getBonusList();
  Future<Either<Failure, LoyaltyHistoryResponse>> getLoyaltyHistory();
}

