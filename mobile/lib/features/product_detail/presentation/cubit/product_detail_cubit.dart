import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/repository/product_detail_repository.dart';

part 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final ProductDetailRepository _productDetailRepository;

  ProductDetailCubit(this._productDetailRepository) : super(ProductDetailInitial());

  ProductDetailSuccess _getCurrentState() {
    if (state is ProductDetailSuccess) {
      return state as ProductDetailSuccess;
    }
    return  ProductDetailSuccess();
  }

  void getProductDetail({required int productId}) async {
    final currentState = _getCurrentState();
    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['detail'] = true,
      errorStates: Map.from(currentState.errorStates)..['detail'] = null,
    ));
    
    final response = await _productDetailRepository.getProductDetail(productId: productId);
    
    // State'ni qayta olish (boshqa operatsiyalar uni o'zgartirgan bo'lishi mumkin)
    final updatedState = state is ProductDetailSuccess ? state as ProductDetailSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['detail'] = false,
        errorStates: Map.from(updatedState.errorStates)..['detail'] = l,
      )),
      (r) => emit(updatedState.copyWith(
        detail: r,
        loadingStates: Map.from(updatedState.loadingStates)..['detail'] = false,
        errorStates: Map.from(updatedState.errorStates)..['detail'] = null,
      )),
    );
  }

  void getGoodVariants({required int productId}) async {
    final currentState = _getCurrentState();
    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['goodVariants'] = true,
      errorStates: Map.from(currentState.errorStates)..['goodVariants'] = null,
    ));
    
    final response = await _productDetailRepository.getGoodVariants(productId: productId);
    
    // State'ni qayta olish (boshqa operatsiyalar uni o'zgartirgan bo'lishi mumkin)
    final updatedState = state is ProductDetailSuccess ? state as ProductDetailSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['goodVariants'] = false,
        errorStates: Map.from(updatedState.errorStates)..['goodVariants'] = l,
      )),
      (r) => emit(updatedState.copyWith(
        goodVariants: r,
        loadingStates: Map.from(updatedState.loadingStates)..['goodVariants'] = false,
        errorStates: Map.from(updatedState.errorStates)..['goodVariants'] = null,
      )),
    );
  }

  void getTicketVariants({required int productId}) async {
    final currentState = _getCurrentState();
    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['ticketVariants'] = true,
      errorStates: Map.from(currentState.errorStates)..['ticketVariants'] = null,
    ));
    
    final response = await _productDetailRepository.getTicketVariants(productId: productId);
    
    // State'ni qayta olish (boshqa operatsiyalar uni o'zgartirgan bo'lishi mumkin)
    final updatedState = state is ProductDetailSuccess ? state as ProductDetailSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['ticketVariants'] = false,
        errorStates: Map.from(updatedState.errorStates)..['ticketVariants'] = l,
      )),
      (r) => emit(updatedState.copyWith(
        ticketVariants: r,
        loadingStates: Map.from(updatedState.loadingStates)..['ticketVariants'] = false,
        errorStates: Map.from(updatedState.errorStates)..['ticketVariants'] = null,
      )),
    );
  }

  void getPhoneVariants({required int productId}) async {
    final currentState = _getCurrentState();
    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['phoneVariants'] = true,
      errorStates: Map.from(currentState.errorStates)..['phoneVariants'] = null,
    ));
    
    final response = await _productDetailRepository.getPhoneVariants(productId: productId);
    
    // State'ni qayta olish (boshqa operatsiyalar uni o'zgartirgan bo'lishi mumkin)
    final updatedState = state is ProductDetailSuccess ? state as ProductDetailSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['phoneVariants'] = false,
        errorStates: Map.from(updatedState.errorStates)..['phoneVariants'] = l,
      )),
      (r) => emit(updatedState.copyWith(
        phoneVariants: r,
        loadingStates: Map.from(updatedState.loadingStates)..['phoneVariants'] = false,
        errorStates: Map.from(updatedState.errorStates)..['phoneVariants'] = null,
      )),
    );
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(ProductDetailInitial());
}
