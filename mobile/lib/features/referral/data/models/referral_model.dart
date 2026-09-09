class ReferralModel {
  final int id;
  final String fullName;
  final String referralCode;
  final num balance;
  final List<ReferralItemModel> myReferralsList;

  ReferralModel({
    required this.id,
    required this.fullName,
    required this.referralCode,
    required this.balance,
    required this.myReferralsList,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      referralCode: json['referral_code'] as String? ?? '',
      balance: json['balance'] as num? ?? 0,
      myReferralsList: (json['my_referrals_list'] as List<dynamic>?)
              ?.map((e) => ReferralItemModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'referral_code': referralCode,
      'balance': balance,
      'my_referrals_list': myReferralsList.map((e) => e.toJson()).toList(),
    };
  }
}

class ReferralItemModel {
  final String friendName;
  final String status;
  final String createdAt;

  ReferralItemModel({
    required this.friendName,
    required this.status,
    required this.createdAt,
  });

  factory ReferralItemModel.fromJson(Map<String, dynamic> json) {
    return ReferralItemModel(
      friendName: json['friend_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friend_name': friendName,
      'status': status,
      'created_at': createdAt,
    };
  }
}
