import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/service/secure_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/b2b_repository.dart';
import '../../data/models/b2b_status_model.dart';
import '../datasource/b2b_remote_datasource.dart';

class B2BRepositoryImpl implements B2BRepository {
  final SecureStorage _storage = SecureStorage();
  final B2BRemoteDataSource remoteDataSource;

  B2BRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, bool>> checkB2BStatus() async {
    try {
      // Reads cached value from storage (synced by getB2BStatus from API)
      final isB2B = await _storage.read(key: 'is_b2b_user');
      return Right(isB2B == 'true');
    } catch (e) {
      logger.e("B2B Status Check Error: $e");
      return Left(Failure(error: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Either<Failure, bool>> registerAsB2B({
    required String companyName,
    required String inn,
    required String address,
    required String contactPerson,
    required String phoneNumber,
    String? extraInfo,
    File? documentImage,
  }) async {
    try {
      // API call via RemoteDataSource
      // INN might be part of extraInfo or just not sent if API doesn't support it directly.
      // Based on typical flows, we send what we have. 
      // If INN is crucial but API has no field, we might append to extraInfo.
      
      String? finalExtraInfo = extraInfo;
      if (inn != 'N/A' && inn.isNotEmpty) {
        finalExtraInfo = "${finalExtraInfo ?? ''} INN: $inn".trim();
      }

      final result = await remoteDataSource.applyForB2B(
        companyName: companyName,
        phone: phoneNumber,
        address: address,
        contactPerson: contactPerson,
        extraInfo: finalExtraInfo,
        documentImage: documentImage,
      );

      if (result) {
        // So'rov yuborildi - status WAITING bo'ladi. getB2BStatus() API dan yangi statusni oladi.
        // is_b2b_user ni API dan olingan status bo'yicha getB2BStatus yangilaydi.
        await _storage.write(key: 'b2b_company_name', value: companyName);
        await _storage.write(key: 'b2b_inn', value: inn);
        await _storage.write(key: 'b2b_address', value: address);
        await _storage.write(key: 'b2b_contact_person', value: contactPerson);
        await _storage.write(key: 'b2b_phone_number', value: phoneNumber);
        return const Right(true);
      } else {
         return Left(Failure(error: "Unknown error during registration", statusCode: 0));
      }
    } catch (e) {
      logger.e("B2B Registration Error: $e");
      return Left(Failure(error: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Either<Failure, bool>> clearB2BStatus() async {
    try {
      await _storage.delete(key: 'is_b2b_user');
      await _storage.delete(key: 'b2b_company_name');
      await _storage.delete(key: 'b2b_inn');
      await _storage.delete(key: 'b2b_address');
      await _storage.delete(key: 'b2b_contact_person');
      await _storage.delete(key: 'b2b_phone_number');
      return const Right(true);
    } catch (e) {
      logger.e("B2B Clear Status Error: $e");
      return Left(Failure(error: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Either<Failure, B2BStatusModel>> getB2BStatus() async {
    try {
      final status = await remoteDataSource.getB2BStatus();

      // Sync is_b2b_user: PENDING/STANDART/REJECTED -> false, boshqa (tasdiqlangan) -> true
      final isApproved = status.isApprovedB2B;
      await _storage.write(key: 'is_b2b_user', value: isApproved.toString());

      return Right(status);
    } catch (e) {
      logger.e("Get B2B Status Error: $e");
      return Left(Failure(error: e.toString(), statusCode: 0));
    }
  }
}
