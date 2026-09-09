class LoyaltyCardModel {
  final int? id;
  final int? profile;
  final String? fullName;
  final double? balance;
  final String? cycleStart;
  final String? cycleEnd;
  final int? cycleDays;
  final int? cycleNumber;
  final String? createdAt;
  final String? updatedAt;

  LoyaltyCardModel({
    this.id,
    this.profile,
    this.fullName,
    this.balance,
    this.cycleStart,
    this.cycleEnd,
    this.cycleDays,
    this.cycleNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory LoyaltyCardModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyCardModel(
      id: json['id'],
      profile: json['profile'],
      fullName: json['full_name'],
      balance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      cycleStart: json['cycle_start'],
      cycleEnd: json['cycle_end'],
      cycleDays: json['cycle_days'],
      cycleNumber: json['cycle_number'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile': profile,
      'full_name': fullName,
      'current_balance': balance?.toStringAsFixed(2),
      'cycle_start': cycleStart,
      'cycle_end': cycleEnd,
      'cycle_days': cycleDays,
      'cycle_number': cycleNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}








