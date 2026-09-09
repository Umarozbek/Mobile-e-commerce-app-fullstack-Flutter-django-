import 'dart:io';
import 'package:dio/dio.dart';
import '../models/b2b_status_model.dart';
import '../../../../core/constans/urls.dart';
import '../../../../core/network/api_client.dart';

abstract class B2BRemoteDataSource {
  Future<bool> applyForB2B({
    required String companyName,
    required String phone,
    required String address,
    required String contactPerson,
    String? extraInfo,
    File? documentImage,
  });

  Future<B2BStatusModel> getB2BStatus();
}

class B2BRemoteDataSourceImpl implements B2BRemoteDataSource {
  // ApiClient is typically a singleton or injected.
  // In this project it seems ApiClient is a singleton registered in DI.
  // But we can also access it via constructor if injected.
  final ApiClient apiClient;

  B2BRemoteDataSourceImpl(this.apiClient);

  @override
  Future<bool> applyForB2B({
    required String companyName,
    required String phone,
    required String address,
    required String contactPerson,
    String? extraInfo,
    File? documentImage,
  }) async {
    final Map<String, dynamic> body = {
      'company_name': companyName,
      'phone': phone,
      'address': address,
      'contact_person': contactPerson,
    };

    if (extraInfo != null && extraInfo.isNotEmpty) {
      body['extra_info'] = extraInfo;
    }

    if (documentImage != null) {
      body['document_image'] = await MultipartFile.fromFile(documentImage.path);
    }

    final response = await apiClient.post(
      MainUrls.b2bApply,
      body: body,
      isMultiPart: true,
    );

    if (response.isSuccess) {
      return true;
    } else {
      throw Exception(response.response.toString());
    }
  }

  @override
  Future<B2BStatusModel> getB2BStatus() async {
    final response = await apiClient.get(MainUrls.b2bStatus);

    if (response.isSuccess) {
      final data = response.response;
      if (data is Map<String, dynamic>) {
        return B2BStatusModel.fromJson(data);
      }
      throw Exception('Invalid B2B status response format');
    } else {
      throw Exception(response.response.toString());
    }
  }
}
