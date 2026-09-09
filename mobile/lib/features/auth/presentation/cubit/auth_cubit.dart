import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/repository/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  void login({required String number, required String password}) async {
    emit(AuthLoading(type: AuthType.login));
    final response = await _authRepository.login(
      number: number,
      password: password,
    );
    response.fold(
      (l) => emit(AuthError(failure: l, type: AuthType.login)),
      (r) => emit(AuthSuccess(type: AuthType.login)),
    );
  }

  void register({
    required String number,
    required String fullName,
    String? referralCode,
  }) async {
    emit(AuthLoading(type: AuthType.signUp));
    final response = await _authRepository.register(
      number: number,
      fullName: fullName,
      referralCode: referralCode,
    );
    response.fold(
      (l) => emit(AuthError(failure: l, type: AuthType.signUp)),
      (r) => emit(AuthSuccess(
        data: r.token ?? '',
        otpDebug: r.otpDebug,
        referralBonusGiven: r.referralBonusGiven,
        type: AuthType.signUp,
      )),
    );
  }

  void verifyOtp({required String phone, required String otp}) async {
    emit(AuthLoading(type: AuthType.verifyOtp));
    final response = await _authRepository.verifyOtp(
     otp: otp, phone: phone,
    );
    response.fold(
      (l) => emit(AuthError(failure: l, type: AuthType.verifyOtp)),
      (r) => emit(AuthSuccess(type: AuthType.verifyOtp)),
    );
  }

  void setPassword({required String phone, required String password}) async {
    emit(AuthLoading(type: AuthType.setPassword));
    final response = await _authRepository.setPassword(

      password: password, phone: phone,
    );
    response.fold(
      (l) => emit(AuthError(failure: l, type: AuthType.setPassword)),
      (r) => emit(AuthSuccess(type: AuthType.setPassword)),
    );
  }

  void resendOtp({
    required String number,
    required String fullName,
    String? referralCode,
  }) async {
    emit(AuthLoading(type: AuthType.resendOtp));
    final response = await _authRepository.register(
      number: number,
      fullName: fullName,
      referralCode: referralCode,
    );
    response.fold(
      (l) => emit(AuthError(failure: l, type: AuthType.resendOtp)),
      (r) => emit(AuthSuccess(
        otpDebug: r.otpDebug,
        type: AuthType.resendOtp,
      )),
    );
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(AuthInitial());
}
