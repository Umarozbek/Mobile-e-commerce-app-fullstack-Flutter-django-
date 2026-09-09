part of 'profile_cubit.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {
  final String? type;
  ProfileLoading({this.type});
  
  @override
  List<Object> get props => [type ?? ''];
}

final class ProfileSuccess extends ProfileState {
  final dynamic data;
  final String? type;
  
  ProfileSuccess({this.data, this.type});
  
  @override
  List<Object> get props => [data ?? '', type ?? ''];
}

final class ProfileError extends ProfileState {
  final Failure failure;
  final String? type;
  
  ProfileError({required this.failure, this.type});
  
  @override
  List<Object> get props => [failure, type ?? ''];
}

