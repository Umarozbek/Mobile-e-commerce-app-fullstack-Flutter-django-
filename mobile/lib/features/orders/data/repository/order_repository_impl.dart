import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constans/api_consts.dart';
import '../../../../core/constans/urls.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../cart/data/models/cart_order_model.dart';
import '../../../locations/data/models/location_model.dart';
import '../../domain/repository/order_repository.dart';
import '../models/order_model.dart';
import '../models/payment_info_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ApiClient _apiClient;
  // Mock data storage (in-memory) - kept for other methods for now
  final List<OrderModel> _orders = [];
  int _nextOrderId = 1;

  OrderRepositoryImpl(this._apiClient);

  @override
  Future<OrderModel> createOrder({
    required List<OrderProductItem> items,
    required LocationModel deliveryAddress,
    required double totalAmount,
    required double deliveryFee,
    String comment = "",
  }) async {
    final response = await _apiClient.post(
      MainUrls.merchantCartCheckout,
      body: {
        "location": deliveryAddress.id,
        "comment": comment,
      },
    );

    if (response.isSuccess) {
      try {
        final data = response.response;
        final orderId = data is Map ? data['order_id'] : null;
        if (orderId == null) {
          throw Exception("Checkout response did not include order_id");
        }
        // Checkout javobida delivery_fee/total_amount tafsiloti to'liq kelmaydi
        // (faqat total_amount bor) — shuning uchun haqiqiy buyurtmani (delivery_fee
        // bilan birga, backend hisoblagan holida) qayta so'raymiz. Klient tomondan
        // hech qanday summa o'ylab topilmaydi.
        return await getOrderById(orderId is int ? orderId : int.parse(orderId.toString()));
      } catch (e) {
        logger.e("Parsing Error: $e");
        throw Exception("Parsing error: $e");
      }
    } else {
      throw Exception(response.response);
    }
  }

  static const int _defaultPageSize = 20;

  String _resolveNextUrl(String nextUrl) {
    if (nextUrl.startsWith('http')) return nextUrl;
    final base = ApiConsts.baseUrl;
    final path = nextUrl.startsWith('/') ? nextUrl.substring(1) : nextUrl;
    return base.endsWith('/') ? '$base$path' : '$base/$path';
  }

  @override
  Future<OrderListResponse> getOrders({int page = 1, int pageSize = _defaultPageSize}) async {
    final url = MainUrls.merchantOrdersList.contains('?')
        ? MainUrls.merchantOrdersList.replaceAll(RegExp(r'page=\d+'), 'page=$page').replaceAll(RegExp(r'page_size=\d+'), 'page_size=$pageSize')
        : '${MainUrls.merchantOrdersList}?page=$page&page_size=$pageSize';
    final response = await _apiClient.get(url);

    if (response.isSuccess) {
      try {
        final data = response.response;
        if (data is Map<String, dynamic> && (data['results'] != null || data.containsKey('next'))) {
          return OrderListResponse.fromJson(data);
        }
        if (data is List) {
          return OrderListResponse(
            results: data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList(),
          );
        }
        return OrderListResponse();
      } catch (e) {
         logger.e("Parsing Error: $e");
         throw Exception("Parsing error: $e");
      }
    } else {
      throw Exception(response.response);
    }
  }

  @override
  Future<OrderListResponse> getOrdersNext(String nextUrl) async {
    final url = _resolveNextUrl(nextUrl);
    final response = await _apiClient.get(url, anotherLink: true);

    if (response.isSuccess) {
      try {
        final data = response.response;
        if (data is Map<String, dynamic>) {
          return OrderListResponse.fromJson(data);
        }
        if (data is List) {
          return OrderListResponse(
            results: data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList(),
          );
        }
        return OrderListResponse();
      } catch (e) {
         logger.e("Parsing Error: $e");
         throw Exception("Parsing error: $e");
      }
    } else {
      throw Exception(response.response);
    }
  }

  @override
  Future<OrderModel> getOrderById(int orderId) async {
    final response = await _apiClient.get('${MainUrls.merchantOrder}$orderId/');

    if (response.isSuccess) {
      try {
        final Map<String, dynamic> data = response.response as Map<String, dynamic>;
        return OrderModel.fromJson(data);
      } catch (e) {
        logger.e("Parsing Error: $e");
        throw Exception("Parsing error: $e");
      }
    } else {
      throw Exception(response.response);
    }
  }

  @override
  Future<OrderModel> submitPayment({
    required int orderId,
    File? checkImage,
    double? loyaltyAmount,
  }) async {
    final Map<String, dynamic> body = {
      "order_id": orderId,
    };

    // Add check image if provided
    if (checkImage != null) {
      final imageFile = await MultipartFile.fromFile(
        checkImage.path,
        filename: checkImage.path.split('/').last,
      );
      body["payment_receipt"] = imageFile;
    }

    // Add loyalty payment amount if provided
    if (loyaltyAmount != null && loyaltyAmount > 0) {
      body["loyalty_payment"] = loyaltyAmount.toInt();
    }

    final response = await _apiClient.post(
      MainUrls.uploadReceipt,
      body: body,
      isMultiPart: true,
    );

    if (response.isSuccess) {
      // Return updated order based on current state + API confirmation
      // Ideally API returns the full order, but here it returns minimal info:
      // { "message": "...", "order_id": 20, "status": "check_pending", "new_loyalty_balance": 55000 }
      
      // We need to fetch the fresh order list or update the local one.
      // Since this method returns OrderModel, let's try to update the local one if found,
      // or fetch it fresh if possible.
      // Given the architecture, the Cubit calls getOrders() after this anyway.
      // So returning a locally patched OrderModel is sufficient for immediate UI feedback.
      
      try {
         // Attempt to find in local list to patch it
         final orderIndex = _orders.indexWhere((order) => order.id == orderId);
         if (orderIndex != -1) {
             final updatedOrder = _orders[orderIndex].copyWith(
              status: response.response['status'] ?? 'check_pending',
              checkImagePath: checkImage?.path, // Local path for display until refresh
              paidAt: DateTime.now(),
              paymentMethod: checkImage != null ? 'receipt' : 'bonus',
              bonusAmount: loyaltyAmount ?? _orders[orderIndex].bonusAmount,
            );
            _orders[orderIndex] = updatedOrder;
            return updatedOrder;
         }
         
         // If not in local list (e.g. freshly started app), return a dummy valid object
         // so Cubit doesn't crash before refreshing list.
         return OrderModel(
            id: orderId,
            orderNumber: 'Updated',
            status: response.response['status'] ?? 'check_pending',
            statusDisplay: 'To\'lov kutilmoqda',
            customerName: '',
            address: '',
            totalAmount: 0.0,
            deliveryFee: 0.0,
            bonusAmount: loyaltyAmount ?? 0.0,
            items: [],
            createdAt: DateTime.now(),
         );

      } catch (e) {
        logger.e("Update local order error: $e");
        rethrow;
      }
    } else {
      throw Exception(response.response);
    }
  }

  @override
  Future<void> cancelOrder(int orderId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex == -1) {
      throw Exception('Buyurtma topilmadi');
    }

    final updatedOrder = _orders[orderIndex].copyWith(
      status: 'cancelled',
    );

    _orders[orderIndex] = updatedOrder;
  }

  @override
  Future<PaymentInfoModel> getPaymentInfo(int orderId) async {
    final response = await _apiClient.get(
      '${MainUrls.uploadReceipt}?order_id=$orderId',
    );

    if (response.isSuccess) {
      try {
        return PaymentInfoModel.fromJson(response.response);
      } catch (e) {
        logger.e("Parsing Error: $e");
        throw Exception("Parsing error: $e");
      }
    } else {
      throw Exception(response.response);
    }
  }
}
