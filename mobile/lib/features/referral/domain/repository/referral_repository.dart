
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/referral_model.dart';

abstract class ReferralRepository {
  Future<Either<Failure, ReferralModel>> getReferralCode();
  Future<Either<Failure, bool>> enterReferralCode({required String code});
}




