import 'dart:io';
import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/b2b_status_model.dart';
import '../../domain/repository/b2b_repository.dart';

part 'b2b_state.dart';

class B2BCubit extends Cubit<B2BState> {
  final B2BRepository _repository;

  B2BCubit(this._repository) : super(B2BInitial());

  /// B2B user holatini tekshirish
  Future<void> checkB2BStatus() async {
    emit(B2BLoading(type: 'checkStatus'));
    final response = await _repository.checkB2BStatus();
    response.fold(
      (failure) => emit(B2BError(failure: failure, type: 'checkStatus')),
      (isB2B) => emit(B2BStatusChecked(isB2BUser: isB2B)),
    );
  }

  /// B2B statusini API orqali tekshirish
  Future<void> getB2BStatus() async {
    emit(B2BLoading(type: 'getStatus'));
    final response = await _repository.getB2BStatus();
    response.fold(
      (failure) => emit(B2BError(failure: failure, type: 'getStatus')),
      (status) => emit(B2BStatusLoaded(status: status)),
    );
  }

  /// B2B user sifatida ro'yxatdan o'tish
  Future<void> registerAsB2B({
    required String companyName,
    required String inn,
    required String address,
    required String contactPerson,
    required String phoneNumber,
    String? extraInfo,
    File? documentImage,
  }) async {
    emit(B2BLoading(type: 'register'));
    final response = await _repository.registerAsB2B(
      companyName: companyName,
      inn: inn,
      address: address,
      contactPerson: contactPerson,
      phoneNumber: phoneNumber,
      extraInfo: extraInfo,
      documentImage: documentImage,
    );
    await response.fold<Future<void>>(
      (failure) async {
        emit(B2BError(failure: failure, type: 'register'));
      },
      (success) async {
        emit(B2BRegistrationSuccess());
        // So'rov yuborilgandan so'ng statusni API dan yangilab,
        // foydalanuvchiga PENDING holatini ko'rsatamiz.
        await getB2BStatus();
      },
    );
  }

  /// B2B user holatini o'chirish
  Future<void> clearB2BStatus() async {
    emit(B2BLoading(type: 'clear'));
    final response = await _repository.clearB2BStatus();
    response.fold(
      (failure) => emit(B2BError(failure: failure, type: 'clear')),
      (success) => emit(B2BStatusCleared()),
    );
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(B2BInitial());
}
