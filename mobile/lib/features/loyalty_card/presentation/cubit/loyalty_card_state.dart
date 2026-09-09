part of 'loyalty_card_cubit.dart';

sealed class LoyaltyCardState extends Equatable {
  const LoyaltyCardState();

  @override
  List<Object> get props => [];
}

final class LoyaltyCardInitial extends LoyaltyCardState {}

final class LoyaltyCardLoading extends LoyaltyCardState {
  @override
  List<Object> get props => [];
}

final class LoyaltyCardSuccess extends LoyaltyCardState {
  final LoyaltyCardModel? data;
  final LoyaltyHistoryResponse? history;

  const LoyaltyCardSuccess({
    this.data,
    this.history,
  });

  LoyaltyCardSuccess copyWith({
    LoyaltyCardModel? data,
    LoyaltyHistoryResponse? history,
  }) {
    return LoyaltyCardSuccess(
      data: data ?? this.data,
      history: history ?? this.history,
    );
  }


}

final class LoyaltyCardError extends LoyaltyCardState {
  final Failure failure;

  const LoyaltyCardError({required this.failure});

  @override
  List<Object> get props => [failure];
}

