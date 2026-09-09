part of 'referral_cubit.dart';

sealed class ReferralState extends Equatable {
  const ReferralState();

  @override
  List<Object> get props => [];
}

final class ReferralInitial extends ReferralState {}

final class ReferralLoading extends ReferralState {
  final String? type;
  ReferralLoading({this.type});
  
  @override
  List<Object> get props => [type ?? ''];
}

final class ReferralSuccess extends ReferralState {
  final dynamic data;
  final String? type;
  
  ReferralSuccess({this.data, this.type});
  
  @override
  List<Object> get props => [data ?? '', type ?? ''];
}

final class ReferralError extends ReferralState {
  final Failure failure;
  final String? type;
  
  ReferralError({required this.failure, this.type});
  
  @override
  List<Object> get props => [failure, type ?? ''];
}

