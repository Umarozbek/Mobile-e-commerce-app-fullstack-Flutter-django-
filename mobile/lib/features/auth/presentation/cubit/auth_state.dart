part of 'auth_cubit.dart';

sealed class AuthState extends Equatable {
  const AuthState();
}


enum AuthType { login, signUp, verifyOtp, setPassword, resendOtp }

final class AuthInitial extends AuthState {
  @override
  List<Object> get props => [];
}

final class AuthLoading extends AuthState {
  final AuthType type;
  const AuthLoading({this.type = AuthType.login});
  @override
  List<Object> get props => [type];
}

final class AuthSuccess extends AuthState {
  final AuthType type;
  final String? data;
  /// Register dan qaytgan otp_debug (faqat development/test uchun).
  final String? otpDebug;
  /// Register javobidagi referral_bonus_given flag.
  final bool referralBonusGiven;
  const AuthSuccess({this.type = AuthType.login, this.data = "", this.otpDebug, this.referralBonusGiven = false});
  @override
  List<Object?> get props => [type, data, otpDebug, referralBonusGiven];
}

final class AuthError extends AuthState {
  final AuthType type;
  final Failure failure;
  const AuthError({required this.failure, this.type = AuthType.login});
  @override
  List<Object> get props => [type, failure];
}
