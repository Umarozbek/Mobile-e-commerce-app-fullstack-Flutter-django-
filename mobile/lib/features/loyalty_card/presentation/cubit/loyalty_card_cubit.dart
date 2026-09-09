import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/loyalty_card_model.dart';
import '../../data/models/loyalty_history_model.dart';
import '../../domain/repository/loyalty_card_repository.dart';

part 'loyalty_card_state.dart';

class LoyaltyCardCubit extends Cubit<LoyaltyCardState> {
  final LoyaltyCardRepository _loyaltyCardRepository;

  LoyaltyCardCubit(this._loyaltyCardRepository) : super(LoyaltyCardInitial());

  void loadLoyaltyData({bool forceRefresh = false}) async {
    if (!forceRefresh && state is LoyaltyCardSuccess && (state as LoyaltyCardSuccess).history != null) return;

    emit(LoyaltyCardLoading());
    final cardResponse = await _loyaltyCardRepository.getBonusList();
    final historyResponse = await _loyaltyCardRepository.getLoyaltyHistory();

    LoyaltyCardModel? cardData;
    LoyaltyHistoryResponse? historyData;
    Failure? failure;

    cardResponse.fold(
      (l) => failure = l,
      (r) => cardData = r,
    );

    if (failure != null) {
      emit(LoyaltyCardError(failure: failure!));
      return;
    }

    historyResponse.fold(
      (l) => null, 
      (r) => historyData = r,
    );

    emit(LoyaltyCardSuccess(data: cardData, history: historyData));
  }

  void getBonusList() async {
    emit(LoyaltyCardLoading());
    final response = await _loyaltyCardRepository.getBonusList();
    response.fold(
      (l) => emit(LoyaltyCardError(failure: l)),
      (r) => emit(LoyaltyCardSuccess(data: r, history: state is LoyaltyCardSuccess ? (state as LoyaltyCardSuccess).history : null)),
    );
  }

  void getLoyaltyHistory() async {
    // This function is kept for compatibility but loadLoyaltyData is preferred
    emit(LoyaltyCardLoading());
    final response = await _loyaltyCardRepository.getLoyaltyHistory();
    response.fold(
      (l) => emit(LoyaltyCardError(failure: l)),
      (r) => emit(LoyaltyCardSuccess(data: state is LoyaltyCardSuccess ? (state as LoyaltyCardSuccess).data : null, history: r)),
    );
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(LoyaltyCardInitial());
}

