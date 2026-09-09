
import 'package:equatable/equatable.dart';

import '../../data/models/order_model.dart';
import '../../data/models/payment_info_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderSuccess extends OrderState {
  final List<OrderModel> orders;
  final OrderModel? order;
  final PaymentInfoModel? paymentInfo;
  final bool isLoading;
  final String? error;
  final String? nextUrl;
  final bool hasMore;
  final bool isLoadingMore;

  const OrderSuccess({
    this.orders = const [],
    this.order,
    this.paymentInfo,
    this.isLoading = false,
    this.error,
    this.nextUrl,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  OrderSuccess copyWith({
    List<OrderModel>? orders,
    OrderModel? order,
    PaymentInfoModel? paymentInfo,
    bool? isLoading,
    String? error,
    String? nextUrl,
    bool? hasMore,
    bool? isLoadingMore,
    bool clearOrder = false,
    bool clearPaymentInfo = false,
  }) {
    return OrderSuccess(
      orders: orders ?? this.orders,
      order: clearOrder ? null : (order ?? this.order),
      paymentInfo: clearPaymentInfo ? null : (paymentInfo ?? this.paymentInfo),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      nextUrl: nextUrl ?? this.nextUrl,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [orders, order, paymentInfo, isLoading, error, nextUrl, hasMore, isLoadingMore];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
