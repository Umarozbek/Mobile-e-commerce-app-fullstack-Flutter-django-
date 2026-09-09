part of 'cart_cubit.dart';

sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object> get props => [];
}

final class CartInitial extends CartState {}

final class CartLoading extends CartState {}

final class CartSuccess extends CartState {
  final List<OrderProductItem> items;
  final double totalPrice;
  final int? orderId;
  final double deliveryFee;

  const CartSuccess({
    required this.items,
    required this.totalPrice,
    this.orderId,
    this.deliveryFee = 0,
  });

  CartSuccess copyWith({
    List<OrderProductItem>? items,
    double? totalPrice,
    int? orderId,
    double? deliveryFee,
  }) {
    return CartSuccess(
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      orderId: orderId ?? this.orderId,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }

  @override
  List<Object> get props => [items, totalPrice];
}

final class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object> get props => [message];
}
