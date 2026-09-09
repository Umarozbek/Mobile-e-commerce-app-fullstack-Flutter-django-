class LoyaltyHistoryResponse {
  final double currentBalance;
  final List<SpendingHistoryItem> spendingHistory;
  final List<CashbackHistoryItem> cashbackHistory;
  final List<ReferralHistoryItem> referralHistory;

  LoyaltyHistoryResponse({
    required this.currentBalance,
    required this.spendingHistory,
    required this.cashbackHistory,
    required this.referralHistory,
  });

  factory LoyaltyHistoryResponse.fromJson(Map<String, dynamic> json) {
    return LoyaltyHistoryResponse(
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      spendingHistory: (json['spending_history'] as List?)
              ?.map((e) => SpendingHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cashbackHistory: (json['cashback_history'] as List?)
              ?.map((e) => CashbackHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      referralHistory: (json['referral_history'] as List?)
              ?.map((e) => ReferralHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Cashback history item: order_number, order_amount, percent, bonus_amount, status, created_at, type.
class CashbackHistoryItem {
  final String orderNumber;
  final String orderAmount;
  final int percent;
  final double bonusAmount;
  final String status;
  final DateTime createdAt;
  final String type;

  CashbackHistoryItem({
    required this.orderNumber,
    required this.orderAmount,
    required this.percent,
    required this.bonusAmount,
    required this.status,
    required this.createdAt,
    required this.type,
  });

  factory CashbackHistoryItem.fromJson(Map<String, dynamic> json) {
    return CashbackHistoryItem(
      orderNumber: json['order_number']?.toString() ?? '',
      orderAmount: json['order_amount']?.toString() ?? '',
      percent: int.tryParse(json['percent']?.toString() ?? '0') ?? 0,
      bonusAmount: double.tryParse(json['bonus_amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      type: json['type']?.toString() ?? 'cashback',
    );
  }
}

class SpendingHistoryItem {
  final String orderNumber;
  final double loyaltyPayment;
  final String status;
  final DateTime createdAt;
  final String type;

  SpendingHistoryItem({
    required this.orderNumber,
    required this.loyaltyPayment,
    required this.status,
    required this.createdAt,
    required this.type,
  });

  factory SpendingHistoryItem.fromJson(Map<String, dynamic> json) {
    return SpendingHistoryItem(
      orderNumber: json['order_number']?.toString() ?? '',
      loyaltyPayment: double.tryParse(json['loyalty_payment']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      type: json['type']?.toString() ?? 'spending',
    );
  }
}

class ReferralHistoryItem {
  final String friendName;
  final double bonusAmount;
  final String status;
  final DateTime createdAt;
  final String type;

  ReferralHistoryItem({
    required this.friendName,
    required this.bonusAmount,
    required this.status,
    required this.createdAt,
    required this.type,
  });

  factory ReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReferralHistoryItem(
      friendName: json['friend_name']?.toString() ?? '',
      bonusAmount: double.tryParse(json['bonus_amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      type: json['type']?.toString() ?? 'referral',
    );
  }
}
