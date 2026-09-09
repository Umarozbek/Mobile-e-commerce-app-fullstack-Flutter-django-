part of 'product_detail_cubit.dart';

sealed class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object> get props => [];
}

final class ProductDetailInitial extends ProductDetailState {}

final class ProductDetailLoading extends ProductDetailState {
  final String? type;
  ProductDetailLoading({this.type});
  
  @override
  List<Object> get props => [type ?? ''];
}

final class ProductDetailSuccess extends ProductDetailState {
  final dynamic detail;
  final dynamic goodVariants;
  final dynamic ticketVariants;
  final dynamic phoneVariants;
  
  final Map<String, bool> loadingStates;
  final Map<String, Failure?> errorStates;
  
  ProductDetailSuccess({
    this.detail,
    this.goodVariants,
    this.ticketVariants,
    this.phoneVariants,
    Map<String, bool>? loadingStates,
    Map<String, Failure?>? errorStates,
  }) : loadingStates = loadingStates ?? {},
       errorStates = errorStates ?? {};
  
  ProductDetailSuccess copyWith({
    dynamic detail,
    dynamic goodVariants,
    dynamic ticketVariants,
    dynamic phoneVariants,
    Map<String, bool>? loadingStates,
    Map<String, Failure?>? errorStates,
    bool? clearDetail,
    bool? clearGoodVariants,
    bool? clearTicketVariants,
    bool? clearPhoneVariants,
  }) {
    return ProductDetailSuccess(
      detail: clearDetail == true ? null : (detail ?? this.detail),
      goodVariants: clearGoodVariants == true ? null : (goodVariants ?? this.goodVariants),
      ticketVariants: clearTicketVariants == true ? null : (ticketVariants ?? this.ticketVariants),
      phoneVariants: clearPhoneVariants == true ? null : (phoneVariants ?? this.phoneVariants),
      loadingStates: loadingStates ?? Map.from(this.loadingStates),
      errorStates: errorStates ?? Map.from(this.errorStates),
    );
  }
  
  @override
  List<Object> get props => [
    detail ?? '',
    goodVariants ?? '',
    ticketVariants ?? '',
    phoneVariants ?? '',
    loadingStates,
    errorStates,
  ];
}

final class ProductDetailError extends ProductDetailState {
  final Failure failure;
  final String? type;
  
  ProductDetailError({required this.failure, this.type});
  
  @override
  List<Object> get props => [failure, type ?? ''];
}
