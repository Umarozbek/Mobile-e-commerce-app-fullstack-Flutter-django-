part of 'b2b_cubit.dart';

sealed class B2BState extends Equatable {
  const B2BState();
  
  @override
  List<Object?> get props => [];
}

final class B2BInitial extends B2BState {}

final class B2BLoading extends B2BState {
  final String type;
  
  const B2BLoading({this.type = 'checkStatus'});
  
  @override
  List<Object?> get props => [type];
}

final class B2BStatusChecked extends B2BState {
  final bool isB2BUser;
  
  const B2BStatusChecked({required this.isB2BUser});
  
  @override
  List<Object?> get props => [isB2BUser];
}

final class B2BStatusLoaded extends B2BState {
  final B2BStatusModel status;

  const B2BStatusLoaded({required this.status});

  @override
  List<Object?> get props => [status];
}

final class B2BRegistrationSuccess extends B2BState {}

final class B2BStatusCleared extends B2BState {}

final class B2BError extends B2BState {
  final Failure failure;
  final String type;
  
  const B2BError({required this.failure, this.type = 'checkStatus'});
  
  @override
  List<Object?> get props => [failure, type];
}
