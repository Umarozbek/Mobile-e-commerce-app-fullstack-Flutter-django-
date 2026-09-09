

import 'dart:io';

import '../../../cart/data/models/cart_order_model.dart';
import '../../../locations/data/models/location_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_info_model.dart';

abstract class OrderRepository {
  /// Buyurtma yaratish
  Future<OrderModel> createOrder({
    required List<OrderProductItem> items,
    required LocationModel deliveryAddress,
    required double totalAmount,
    required double deliveryFee,
    String comment = "",
  });

  /// Buyurtmalar ro'yxati (birinchi sahifa, page_size=20)
  Future<OrderListResponse> getOrders({int page = 1, int pageSize = 20});

  /// Keyingi sahifa (pagination)
  Future<OrderListResponse> getOrdersNext(String nextUrl);

  /// Bitta buyurtmani olish
  Future<OrderModel> getOrderById(int orderId);

  /// To'lov qilish (check yuklash yoki bonus ishlatish)
  Future<OrderModel> submitPayment({
    required int orderId,
    File? checkImage,
    double? loyaltyAmount,
  });

  /// Buyurtmani bekor qilish
  Future<void> cancelOrder(int orderId);

  /// To'lov ma'lumotlarini olish (karta, loyalty balans)
  Future<PaymentInfoModel> getPaymentInfo(int orderId);
}
