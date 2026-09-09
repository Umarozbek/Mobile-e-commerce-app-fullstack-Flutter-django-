import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

import '../../../home/data/models/product_model.dart';
import '../../data/models/cart_order_model.dart';
import '../../domain/repository/cart_repository.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepository repository;

  CartCubit(this.repository) : super(CartInitial()) {
    loadCart();
  }

  List<OrderProductItem> _cartItems = [];
  int? _orderId;
  double _deliveryFee = 0;

  Future<void> loadCart() async {
    emit(CartLoading());
    final result = await repository.getCart();
    result.fold(
      (failure) => emit(CartError(failure.error)),
      (response) {
        if (response.results!.isNotEmpty) {
          final order = response.results!.first;
          _orderId = order.id;
          _deliveryFee = order.deliveryFee?.toDouble() ?? 0;
          _cartItems = order.productsDetails!.map((item) {
            return item.copyWith(orderId: _orderId);
          }).toList();
          _calculateTotal();
        } else {
          _cartItems = [];
          _orderId = null;
          emit(CartSuccess(items: [], totalPrice: 0));
        }
      },
    );
  }

  void _calculateTotal() {
    final total = _cartItems.fold(0.0, (sum, item) {
       return sum + ((item.price ?? 0) * (item.quantity ?? 1));
    });
    
    emit(CartSuccess(
      items: List.from(_cartItems),
      totalPrice: total,
      orderId: _orderId,
      deliveryFee: _deliveryFee,
    ));
  }

  Future<void> addToCart(
    ProductModel product, 
    {
      int quantity = 1,
      int? variantId,  // New: Accept variant ID for multi-product support
    }
  ) async {
    // Use variant ID if provided (for multi-products), otherwise use main product ID
    final productId = variantId ?? product.product?.id;
    if (productId == null) return;

    // Call API to add item to cart
    final result = await repository.addItemToCart(
      productId: productId,
      quantity: quantity,
    );

    result.fold(
      (failure) {
        // Show error message or handle failure
        // Error will be visible in UI through state
      },
      (_) async {
        // Success - reload cart to get updated data
        await loadCart();
      },
    );
  }

  Future<void> updateQuantity(int productId, int newQuantity, {int? orderId}) async {
    if (newQuantity <= 0) {
      // Find item by productId to get the item ID for deletion
      final item = _cartItems.firstWhere(
        (item) => item.id == productId,
        orElse: () => OrderProductItem(),
      );
      if (item.id != null) {
        await removeFromCart(item.id!);
      }
      return;
    }

    // Optimistically update local state
    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) {
      final oldItem = _cartItems[index];
      // Sync totalPrice for the item as well so individual item display is correct if used
      final newTotalPrice = (oldItem.price ?? 0) * newQuantity;
      final newItem = oldItem.copyWith(
        quantity: newQuantity,
        totalPrice: newTotalPrice,
      );
      
      _cartItems[index] = newItem;
      _calculateTotal();

      // Call API to update quantity on server
      final result = await repository.updateQuantity(
        productId: productId,
        quantity: newQuantity,
        orderId: orderId ?? _orderId ?? 0,
      );
      
      result.fold(
        (failure) {
          // If API call fails, revert change
          _cartItems[index] = oldItem;
           _calculateTotal();
          
          // Optionally show error
        },
        (_) {
          // Success - local state matches server state (assumed)
        },
      );
    }
  }

  Future<void> removeFromCart(int itemId) async {
    // Optimistically remove from local state
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index == -1) return;
    
    final removedItem = _cartItems[index];
    final productId = removedItem.productId ?? removedItem.id ?? 0;
    final orderId = removedItem.orderId ?? _orderId ?? 0;

    _cartItems.removeAt(index);
    _calculateTotal();

    // Call API to delete from server
    final result = await repository.deleteCartItem(
      orderId: orderId,
      productId: productId,
    );
    result.fold(
      (failure) {
        // If API call fails, revert change
        _cartItems.insert(index, removedItem);
        _calculateTotal();
      },
      (_) {
        // Success - item already removed locally
      },
    );
  }

  void clearCart() {
    _cartItems.clear();
    _orderId = null;
    _calculateTotal();
  }

  /// Logout paytida state tozalanadi
  void reset() {
    _cartItems.clear();
    _orderId = null;
    _deliveryFee = 0;
    emit(CartSuccess(items: [], totalPrice: 0));
  }

  int getCartItemCount() {
    return _cartItems.fold<int>(
      0,
      (sum, item) => sum + (item.quantity ?? 1).toInt(),
    );
  }

  bool isInCart(int productId) {
    return _cartItems.any(
      (item) => item.productId == productId || item.id == productId,
    );
  }

  /// Cart ichidan mahsulotni productId yoki id bo'yicha topish
  OrderProductItem? findCartItem(int productId) {
    for (final item in _cartItems) {
      if (item.productId == productId) return item;
    }
    for (final item in _cartItems) {
      if (item.id == productId) return item;
    }
    return null;
  }
}
