enum OrderStatus {
  inCart,
  pending,
  awaitingConfirmation,
  paymentPending,
  pendingPayment,
  checkPending,
  approved,
  confirmed,
  completed,
  delivered,
  sent,
  cancelled;

  /// API'dan kelgan status string'ini OrderStatus'ga aylantiradi.
  /// Mos kelmasa null qaytaradi.
  static OrderStatus? maybeFrom(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase().trim()) {
      case 'in_cart':
      case 'incart':
        return OrderStatus.inCart;
      case 'pending':
        return OrderStatus.pending;
      case 'awaiting_confirmation':
      case 'awaitingconfirmation':
        return OrderStatus.awaitingConfirmation;
      case 'payment_pending':
      case 'paymentpending':
        return OrderStatus.paymentPending;
      case 'pending_payment':
      case 'pendingpayment':
        return OrderStatus.pendingPayment;
      case 'check_pending':
      case 'checkpending':
        return OrderStatus.checkPending;
      case 'approved':
        return OrderStatus.approved;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'completed':
        return OrderStatus.completed;
      case 'delivered':
        return OrderStatus.delivered;
      case 'sent':
        return OrderStatus.sent;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return null;
    }
  }

  /// Tarjima kaliti — easy_localization orqali lokalizatsiya qilinadi.
  String get translationKey {
    switch (this) {
      case OrderStatus.inCart:
        return 'in_cart_status';
      case OrderStatus.pending:
        return 'pending_status';
      case OrderStatus.awaitingConfirmation:
        return 'awaiting_confirmation_status';
      case OrderStatus.paymentPending:
        return 'payment_pending_status';
      case OrderStatus.pendingPayment:
        return 'pending_payment_status';
      case OrderStatus.checkPending:
        return 'check_pending_status';
      case OrderStatus.approved:
        return 'approved_status';
      case OrderStatus.confirmed:
        return 'confirmed_status';
      case OrderStatus.completed:
        return 'completed_status';
      case OrderStatus.delivered:
        return 'delivered_status';
      case OrderStatus.sent:
        return 'sent_status';
      case OrderStatus.cancelled:
        return 'cancelled_status';
    }
  }

  /// Status tugallangan yoki yo'qligini tekshiradi
  bool get isFinished =>
      this == OrderStatus.completed ||
      this == OrderStatus.delivered ||
      this == OrderStatus.sent ||
      this == OrderStatus.cancelled;

  /// Status faol (jarayonda) yoki yo'qligini tekshiradi
  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.awaitingConfirmation ||
      this == OrderStatus.paymentPending ||
      this == OrderStatus.pendingPayment ||
      this == OrderStatus.checkPending ||
      this == OrderStatus.approved ||
      this == OrderStatus.confirmed;
}
