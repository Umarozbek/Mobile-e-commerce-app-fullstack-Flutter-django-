import 'dart:io';
import 'package:bloc/bloc.dart';



import '../../../cart/data/models/cart_order_model.dart';
import '../../../locations/data/models/location_model.dart';
import '../../domain/repository/order_repository.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _repository;

  OrderCubit(this._repository) : super(OrderInitial());
  
  OrderSuccess _getCurrentState() {
    if (state is OrderSuccess) {
      return state as OrderSuccess;
    }
    return const OrderSuccess();
  }

  /// Buyurtma yaratish
  Future<void> createOrder({
    required List<OrderProductItem> items,
    required LocationModel deliveryAddress,
    required double totalAmount,
    required double deliveryFee,
    String comment = "",
  }) async {
    try {
      emit(OrderLoading());

      final order = await _repository.createOrder(
        items: items,
        deliveryAddress: deliveryAddress,
        totalAmount: totalAmount,
        deliveryFee: deliveryFee,
        comment: comment,
      );

      emit(_getCurrentState().copyWith(order: order));

      // Buyurtma yaratilgandan so'ng ro'yxatni fon rejimida yangilaymiz,
      // foydalanuvchi Orders sahifasiga o'tishda kutib qolmasin.
      getOrders();
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Barcha buyurtmalarni olish (birinchi sahifa, page_size=20)
  Future<void> getOrders() async {
    try {
      final previousState = _getCurrentState();
      if (state is! OrderSuccess) {
        // Birinchi ochilishda to'liq loading holatini ko'rsatamiz
        emit(OrderLoading());
      } else {
        // Qayta kirilganda mavjud ro'yxatni saqlagan holda faqat isLoading flag'ini yoqamiz
        emit(previousState.copyWith(isLoading: true));
      }

      final response = await _repository.getOrders(page: 1, pageSize: 20);

      emit(previousState.copyWith(
        orders: response.results,
        nextUrl: response.next,
        hasMore: response.next != null,
        isLoading: false,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Keyingi sahifa (pagination)
  Future<void> loadMoreOrders() async {
    final currentState = _getCurrentState();
    final nextUrl = currentState.nextUrl;
    if (nextUrl == null || currentState.isLoadingMore) return;

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final response = await _repository.getOrdersNext(nextUrl);

      emit(_getCurrentState().copyWith(
        orders: [...currentState.orders, ...response.results],
        nextUrl: response.next,
        hasMore: response.next != null,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(_getCurrentState().copyWith(isLoadingMore: false));
      emit(OrderError(e.toString()));
    }
  }

  /// Bitta buyurtmani olish
  Future<void> getOrderById(int orderId) async {
    try {
      // Eski order ni tozalab, loading ko'rsatish
      emit(_getCurrentState().copyWith(clearOrder: true, isLoading: true));

      final order = await _repository.getOrderById(orderId);

      emit(_getCurrentState().copyWith(order: order, isLoading: false));
    } catch (e) {
      // Detail sahifa uchun xatolik bo'lsa ham, umumiy orders ro'yxatini o'chirmaymiz.
      // Shunchaki joriy OrderSuccess ichida error maydonini to'ldiramiz.
      emit(_getCurrentState().copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// To'lov qilish
  Future<void> submitPayment({
    required int orderId,
    File? checkImage,
    double? loyaltyAmount,
  }) async {
    try {
      final currentState = _getCurrentState();
      emit(currentState.copyWith(isLoading: true, error: null));

      final order = await _repository.submitPayment(
        orderId: orderId,
        checkImage: checkImage,
        loyaltyAmount: loyaltyAmount,
      );

      // Lokal ro'yxatda ham shu buyurtmani darhol yangilab qo'yamiz (optimistik update)
      final updatedOrders = currentState.orders
          .map((o) => o.id == order.id ? order : o)
          .toList();

      emit(currentState.copyWith(
        orders: updatedOrders,
        order: order,
        isLoading: false,
      ));

      // To'lov qilingandan so'ng ro'yxatni fon rejimida yangilaymiz
      getOrders();
    } catch (e) {
      // To'lov xatolik bo'lsa ham orders ro'yxatini saqlaymiz, faqat error ni yangilaymiz.
      emit(_getCurrentState().copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// To'lov ma'lumotlarini olish (karta, loyalty balans)
  Future<void> getPaymentInfo(int orderId) async {
    try {
      emit(_getCurrentState().copyWith(clearPaymentInfo: true, isLoading: true, error: null));

      final paymentInfo = await _repository.getPaymentInfo(orderId);

      emit(_getCurrentState().copyWith(paymentInfo: paymentInfo, isLoading: false));
    } catch (e) {
      // Payment method sahifasi uchun ham OrderError emas, mavjud state ichida error saqlaymiz.
      emit(_getCurrentState().copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Buyurtmani bekor qilish
  Future<void> cancelOrder(int orderId) async {
    try {
      emit(_getCurrentState().copyWith(isLoading: true, error: null));

      await _repository.cancelOrder(orderId);

      // Bekor qilingandan so'ng ro'yxatni yangilash
      await getOrders();
      emit(_getCurrentState().copyWith(isLoading: false));
    } catch (e) {
      // Bekor qilishda ham ro'yxatni tushirmaymiz, faqat error maydonini to'ldiramiz.
      emit(_getCurrentState().copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(OrderInitial());
}
