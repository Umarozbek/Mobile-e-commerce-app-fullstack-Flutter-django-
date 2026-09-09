import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/b2b_status_model.dart';

abstract class B2BRepository {
  /// B2B user holatini tekshirish
  Future<Either<Failure, bool>> checkB2BStatus();
  
  /// B2B user sifatida ro'yxatdan o'tish
  Future<Either<Failure, bool>> registerAsB2B({
    required String companyName,
    required String inn,
    required String address,
    required String contactPerson,
    required String phoneNumber,
    String? extraInfo,
    File? documentImage,
  });
  
  /// B2B user holatini o'chirish
  Future<Either<Failure, bool>> clearB2BStatus();

  /// B2B statusini API dan olish
  Future<Either<Failure, B2BStatusModel>> getB2BStatus();
}
