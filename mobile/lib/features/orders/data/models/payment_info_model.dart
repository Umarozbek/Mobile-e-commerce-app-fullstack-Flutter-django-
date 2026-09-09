class PaymentInfoModel {
  final int? orderId;
  final String? orderNumber;
  final double? totalAmount;
  final String? bankCardNumber;
  final String? bankCardHolder;
  final double? loyaltyBalance;

  const PaymentInfoModel({
    this.orderId,
    this.orderNumber,
    this.totalAmount,
    this.bankCardNumber,
    this.bankCardHolder,
    this.loyaltyBalance,
  });

  factory PaymentInfoModel.fromJson(Map<String, dynamic> json) {
    return PaymentInfoModel(
      orderId: json['order_id'],
      orderNumber: json['order_number'],
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0'),
      bankCardNumber: json['bank_card_number']?.toString(),
      bankCardHolder: json['bank_card_holder']?.toString(),
      loyaltyBalance: double.tryParse(json['loyalty_balance']?.toString() ?? '0'),
    );
  }

  bool get hasLoyaltyBalance => (loyaltyBalance ?? 0) > 0;
  bool get hasSufficientLoyalty => (loyaltyBalance ?? 0) >= (totalAmount ?? 0);
}

