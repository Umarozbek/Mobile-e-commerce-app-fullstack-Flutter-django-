class B2BStatusModel {
  final String? status;
  final bool? isWholesaler;
  final bool? isApproved;
  final String? message;

  B2BStatusModel({
    this.status,
    this.isWholesaler,
    this.isApproved,
    this.message,
  });

  factory B2BStatusModel.fromJson(Map<String, dynamic> json) {
    return B2BStatusModel(
      status: json['status']?.toString(),
      isWholesaler: json['is_wholesaler'] is bool
          ? json['is_wholesaler'] as bool
          : (json['is_wholesaler']?.toString().toLowerCase() == 'true'),
      isApproved: json['is_approved'] is bool
          ? json['is_approved'] as bool
          : (json['is_approved']?.toString().toLowerCase() == 'true'),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'is_wholesaler': isWholesaler,
      'is_approved': isApproved,
      'message': message,
    };
  }

  /// PENDING: so'rov yuborilgan, tasdiqlash kutilmoqda
  bool get isPending =>
      status != null && status!.toUpperCase() == 'PENDING';

  /// STANDART: hali so'rov yuborilmagan, so'rov yuborish ochiq
  bool get isStandart =>
      status != null && status!.toUpperCase() == 'STANDART';

  /// REJECTED: ariza rad etilgan
  bool get isRejected =>
      status != null && status!.toUpperCase() == 'REJECTED';

  /// So'rov yuborish tugmasi faqat STANDART bo'lganda ko'rsatiladi
  bool get canShowSendRequest => isStandart;

  /// Tasdiqlangan B2B (is_approved = true yoki status boshqa
  /// maxsus holatlar: PENDING, STANDART, REJECTED bo'lmaganda)
  bool get isApprovedB2B =>
      isApproved == true ||
      isWholesaler == true ||
      (status != null && status!.toUpperCase() == 'APPROVED');
}
