import 'package:equatable/equatable.dart';

class OrderTimeline extends Equatable {
  final bool step1Created;
  final String? step1Date;
  final bool step2Paid;
  final String? step2Date;
  final bool step3Approved;
  final String? step3Date;
  final String currentStatus;

  const OrderTimeline({
    required this.step1Created,
    this.step1Date,
    required this.step2Paid,
    this.step2Date,
    required this.step3Approved,
    this.step3Date,
    required this.currentStatus,
  });

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    return OrderTimeline(
      step1Created: json['step1_created'] ?? false,
      step1Date: json['step1_date'],
      step2Paid: json['step2_paid'] ?? false,
      step2Date: json['step2_date'],
      step3Approved: json['step3_approved'] ?? false,
      step3Date: json['step3_date'],
      currentStatus: json['current_status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step1_created': step1Created,
      'step1_date': step1Date,
      'step2_paid': step2Paid,
      'step2_date': step2Date,
      'step3_approved': step3Approved,
      'step3_date': step3Date,
      'current_status': currentStatus,
    };
  }

  @override
  List<Object?> get props => [
        step1Created,
        step1Date,
        step2Paid,
        step2Date,
        step3Approved,
        step3Date,
        currentStatus,
      ];
}
