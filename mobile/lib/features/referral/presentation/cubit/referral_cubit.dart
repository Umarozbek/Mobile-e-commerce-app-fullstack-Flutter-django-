import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/repository/referral_repository.dart';

part 'referral_state.dart';

class ReferralCubit extends Cubit<ReferralState> {
  final ReferralRepository _referralRepository;

  ReferralCubit(this._referralRepository) : super(ReferralInitial());

  void getReferralCode({bool forceRefresh = false}) async {
    String type = "getReferralCode";
    if (!forceRefresh && state is ReferralSuccess && (state as ReferralSuccess).type == type) return;

    emit(ReferralLoading(type: type));
    final response = await _referralRepository.getReferralCode();
    response.fold(
      (l) => emit(ReferralError(failure: l, type: type)),
      (r) => emit(ReferralSuccess(data: r, type: type)),
    );
  }

  void enterReferralCode({required String code}) async {
    String type = "enterReferralCode";
    emit(ReferralLoading(type: type));
    final response = await _referralRepository.enterReferralCode(code: code);
    response.fold(
      (l) => emit(ReferralError(failure: l, type: type)),
      (r) => emit(ReferralSuccess(data: r, type: type)),
    );
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(ReferralInitial());
}

