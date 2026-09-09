import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mart/features/orders/presentation/page/payment_method_selection_page.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order_status.dart';
import '../../../loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderCubit>().getOrderById(widget.orderId);
      // Cashback tarixi allaqachon yuklangan bo'lsa, qayta so'rov yubormaydi
      // (loadLoyaltyData ichidagi cache tekshiruvi tufayli).
      context.read<LoyaltyCardCubit>().loadLoyaltyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('order_details'.tr()),

        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
        // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) return _buildLoading();
          if (state is OrderError) return _buildErrorState(state.message);

          if (state is OrderSuccess) {
            // Agar detail uchun xatolik bo'lsa, lekin umumiy OrderSuccess saqlangan bo'lsa
            if (!state.isLoading && state.order == null && state.error != null) {
              return _buildErrorState(state.error!);
            }
            if (state.isLoading && state.order == null) return _buildLoading();
            if (state.order != null) return _buildContent(state.order!);
          }

          return _buildLoading();
        },
      ),
      bottomNavigationBar: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderSuccess && state.order != null) {
            return _buildBottomBar(state.order!) ?? const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.5),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.read<OrderCubit>().getOrderById(widget.orderId),
                icon: const Icon(Icons.refresh, size: 20),
                label: Text('retry'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════ CONTENT ═════════════════════════

  Widget _buildContent(OrderModel order) {
    return RefreshIndicator(
      onRefresh: () => context.read<OrderCubit>().getOrderById(widget.orderId),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeaderCard(order),
            _buildBonusEarnedBanner(order),
            const SizedBox(height: 16),

            if (order.timeline != null) ...[
              _buildTimelineCard(order),
              const SizedBox(height: 16),
            ],

            if (order.items != null && order.items!.isNotEmpty) ...[
              _buildItemsCard(order),
              const SizedBox(height: 16),
            ],

            if (order.address != null && order.address!.isNotEmpty) ...[
              _buildAddressCard(order),
              const SizedBox(height: 16),
            ],

            // if (_hasPaymentInfo(order)) ...[
            //   _buildPaymentCard(order),
            //   const SizedBox(height: 16),
            // ],

            // _buildPriceSummaryCard(order),
            // const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ═══════════════ HEADER CARD ═══════════════

  Widget _buildHeaderCard(OrderModel order) {
    // Mahsulotlar summasi — itemlar orqali qayta hisoblaymiz
    final itemsTotal = (order.items ?? [])
        .fold<double>(0, (sum, item) => sum + (item.totalPrice));
    // Yetkazib berish narxi backenddan keladi (og'irlikka asoslangan tarif) — Flutter buni o'ylab topmaydi.
    final delivery = order.deliveryFee ?? 0;
    final bonus = order.bonusAmount ?? 0;
    final loyalty = order.loyaltyPayment ?? 0;

    // Backend total_amount ni ustun qo'yamiz; bo'lmasa o'zimiz hisoblaymiz
    final calculatedTotal = itemsTotal + delivery - bonus - loyalty;
    final total = order.totalAmount ?? calculatedTotal;
    return _Card(
      child: Column(
        spacing: AppDimens.s10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('order_number_label'.tr()),
              Text(
              order.orderNumber ?? '№${order.id}',
              style: TextStyle(
                fontSize: AppDimens.s20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),

          ],),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('order_customer_label'.tr()),
              Text(
              order.customerName!,
              style: TextStyle(
                fontSize: AppDimens.s16,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),

          ],),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('order_status_label'.tr()),
              _StatusBadge(status: order.status ?? '', statusDisplay: order.statusDisplay ?? ''),

          ],),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('delivery'.tr()),
              Text(
                '${NumberFormat('#,###').format(delivery)} ₩',
                style: TextStyle(fontSize: AppDimens.s16, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: -0.5),
              ),

          ],),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('order_total_label'.tr()),
              Text(
                '${NumberFormat('#,###').format(total)} ₩',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: -0.5),
              ),
              
          ],),

        ],
      ),
    );
  }

  // ═══════════════ BONUS EARNED BANNER ═══════════════
  // Bonus summasi FAQAT backenddan (loyalty cashback tarixi) olinadi.
  // Buyurtma "tugallandi" degani hali bonus berilgan degani emas — shuning
  // uchun bu banner faqat backend shu buyurtma uchun tasdiqlangan ("approved")
  // cashback yozuvini qaytarsa ko'rinadi, aks holda hech narsa chiqarilmaydi.
  Widget _buildBonusEarnedBanner(OrderModel order) {
    return BlocBuilder<LoyaltyCardCubit, LoyaltyCardState>(
      builder: (context, state) {
        if (state is! LoyaltyCardSuccess || state.history == null) {
          return const SizedBox.shrink();
        }
        final match = state.history!.cashbackHistory
            .where((c) => c.orderNumber == order.orderNumber && c.status == 'approved' && c.bonusAmount > 0)
            .toList();
        if (match.isEmpty) return const SizedBox.shrink();
        final bonusAmount = match.first.bonusAmount;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.success.withOpacity(0.15) : AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.celebration_outlined, color: AppColors.success, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'order_completed_bonus_earned'.tr(),
                    style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
                Text(
                  '+${NumberFormat('#,###').format(bonusAmount)} ₩',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.success),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════ TIMELINE CARD ═══════════════

  Widget _buildTimelineCard(OrderModel order) {
    final t = order.timeline;
    // Statusni order.status dan, bo'lmasa timeline.current_status dan olamiz
    final timelineStatus = t != null ? OrderStatus.maybeFrom(t.currentStatus) : null;
    final status = OrderStatus.maybeFrom(order.status) ?? timelineStatus;

    // Quyidagi statuslarda to'lov amalda bajarilgan deb hisoblaymiz
    // (backend step2 ni null yuborsa ham UI'da \"To'lov qilindi\" completed bo'ladi):
    // pending, awaitingConfirmation, checkPending, approved, confirmed, completed, delivered, sent.
    // payment_pending / pending_payment esa HAQIQIY to'lov hali tugamagan holat,
    // ular uchun step2 faqat real paid bo'lsa true bo'ladi.
    final isPendingOrAbove = status != null &&
        (status == OrderStatus.pending ||
            status == OrderStatus.awaitingConfirmation ||
            status == OrderStatus.checkPending ||
            status == OrderStatus.approved ||
            status == OrderStatus.confirmed ||
            status == OrderStatus.completed ||
            status == OrderStatus.delivered ||
            status == OrderStatus.sent);

    final step1 = t?.step1Created ?? true;
    // Haqiqiy to'lov flag'i: timeline.step2_paid yoki paid_at bo'lsa
    final hasRealPaid = (t?.step2Paid ?? false) || order.paidAt != null;
    // UI da completed ko'rinishi: real to'lov bo'lsa yoki status pending va undan yuqori bo'lsa
    final step2 = hasRealPaid || isPendingOrAbove;
    final step3 = t?.step3Approved ?? (order.confirmedAt != null);
    final step4 = status != null &&
        (status == OrderStatus.completed ||
            status == OrderStatus.delivered ||
            status == OrderStatus.sent);

    // Agar buyurtma yakuniy holatga (completed/delivered/sent) o'tgan bo'lsa,
    // timeline dagi barcha bosqichlar UI'da bajarilgan (completed) bo'lib ko'rinsin.
    final allStepsCompleted = step4;

    DateTime? _parseDate(String? raw) =>
        raw != null ? DateTime.tryParse(raw) : null;

    // 2-bosqich (To'lov) sanasi: faqat haqiqiy sana bo'lsa (step2_date yoki paid_at)
    final paidDate = _parseDate(t?.step2Date) ?? order.paidAt;

    return _Card(
      child: Column(
        children: [
          _TimelineStep(
            title: 'order_placed'.tr(),
            date: t?.step1Date != null ? DateTime.tryParse(t!.step1Date!) : order.createdAt,
            isCompleted: allStepsCompleted ? true : step1,
            isLast: false,
          ),
          _TimelineStep(
            title: 'paid'.tr(),
            date: paidDate,
            isCompleted: allStepsCompleted ? true : step2,
            isLast: false,
          ),
          _TimelineStep(
            title: 'approved_status'.tr(),
            date: _parseDate(t?.step3Date) ?? order.confirmedAt,
            isCompleted: allStepsCompleted ? true : step3,
            isLast: false,
          ),
          _TimelineStep(
            title: 'delivered_status'.tr(),
            date: null,
            isCompleted: step4,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ═══════════════ ITEMS CARD ═══════════════

  Widget _buildItemsCard(OrderModel order) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          _buildSectionTitle('order_products'.tr()),
          Column(
            children: order.items!.asMap().entries.map((entry) {
              return _buildItemRow(entry.value, entry.key < order.items!.length - 1);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item, bool showDivider) {
    // We already built robust fallback logic into item.displayName
    // It will properly handle null or empty values across all available languages.
    final name = item.displayName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: item.productImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(width: 52, height: 52, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                  errorWidget: (context, url, error) => Container(
                    width: 52, height: 52,
                    color: isDark ? Colors.white : Colors.grey.shade100,
                    child: Icon(Icons.image, color: Colors.black, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: AppDimens.s16,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.quantity} x ${NumberFormat('#,###').format(item.price)} ₩',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${NumberFormat('#,###').format(item.totalPrice)} ₩',
                style: TextStyle(
                  fontSize: AppDimens.s16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
      ],
    );
  }

  // ═══════════════ ADDRESS CARD ═══════════════

  Widget _buildAddressCard(OrderModel order) {
    bool isDark=Theme.of(context).brightness==Brightness.dark;
    return _Card(
      child: Column(
        spacing: AppDimens.s10,
        children: [
          _buildSectionTitle('delivery_addresses'.tr()),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark?AppColors.bgSecondaryDark:AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(Assets.icons.location),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  order.address ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════ PAYMENT CARD ═══════════════

  bool _hasPaymentInfo(OrderModel order) {
    return order.paidAt != null ||
        (order.loyaltyPayment != null && order.loyaltyPayment! > 0) ||
        order.formattedCardNumber != null ||
        order.checkImagePath != null;
  }

  Widget _buildPaymentCard(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('pay'.tr()),
        const SizedBox(height: 10),
        _Card(
          child: Column(
            children: [
              if (order.paidAt != null)
                _PaymentRow(
                  icon: Icons.check_circle, label: 'paid'.tr(),
                  value: DateFormat('dd.MM.yyyy HH:mm').format(order.paidAt!),
                  color: Colors.green,
                ),
              if (order.loyaltyPayment != null && order.loyaltyPayment! > 0)
                _PaymentRow(
                  icon: Icons.stars, label: 'payment_bonus'.tr(),
                  value: '${NumberFormat('#,###').format(order.loyaltyPayment)} ₩',
                  color: Colors.orange,
                ),
              if (order.formattedCardNumber != null)
                _PaymentRow(icon: Icons.credit_card, label: 'payment_card'.tr(), value: order.formattedCardNumber!),
              if (order.checkImagePath != null)
                _PaymentRow(icon: Icons.receipt_long, label: 'receipt_uploaded'.tr(), value: '', color: Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════ PRICE SUMMARY ═══════════════

  Widget _buildPriceSummaryCard(OrderModel order) {
    final itemsTotal = (order.items ?? [])
        .fold<double>(0, (sum, item) => sum + (item.totalPrice));
    // Yetkazib berish narxi backenddan keladi (og'irlikka asoslangan tarif) — Flutter buni o'ylab topmaydi.
    final delivery = order.deliveryFee ?? 0;
    final bonus = order.bonusAmount ?? 0;
    final loyalty = order.loyaltyPayment ?? 0;

    final calculatedTotal = itemsTotal + delivery - bonus - loyalty;
    final total = order.totalAmount ?? calculatedTotal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'order_products'.tr(), value: itemsTotal),
          if (delivery > 0) ...[const SizedBox(height: 10), _PriceRow(label: 'delivery'.tr(), value: delivery)],
          if (bonus > 0) ...[const SizedBox(height: 10), _PriceRow(label: 'bonus'.tr(), value: -bonus, isDiscount: true)],
          if (loyalty > 0) ...[const SizedBox(height: 10), _PriceRow(label: 'payment_bonus'.tr(), value: -loyalty, isDiscount: true)],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('cart_total'.tr(), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
              Text(
                '${NumberFormat('#,###').format(total)} ₩',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════ BOTTOM BAR ═══════════════

  Widget? _buildBottomBar(OrderModel order) {
    final needsPayment = order.status == 'pending_payment' ||
        order.status == 'check_pending' ||
        order.status == 'payment_pending';
    if (!needsPayment) return null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentMethodSelectionPage(order: order))),
            icon: const Icon(Icons.payment, size: 20),
            label: Text('make_payment'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════ HELPERS ═══════════════

  Widget _buildSectionTitle(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Icon(icon, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        // const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
      ],
    );
  }
}

// ═══════════════════════ REUSABLE WIDGETS ═══════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    bool isDark=Theme.of(context).brightness==Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        // borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _PaymentRow({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const Spacer(),
          if (value.isNotEmpty)
            Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color ?? Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String statusDisplay;

  const _StatusBadge({required this.status, this.statusDisplay = ''});

  Color get _color {
    final orderStatus = OrderStatus.maybeFrom(status);
    if (orderStatus == null) return Colors.grey;
    switch (orderStatus) {
      case OrderStatus.inCart:
        return Colors.grey;
      case OrderStatus.pending:
      case OrderStatus.awaitingConfirmation:
        return Colors.blue;
      case OrderStatus.paymentPending:
      case OrderStatus.pendingPayment:
      case OrderStatus.checkPending:
        return Colors.orange;
      case OrderStatus.approved:
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.completed:
      case OrderStatus.delivered:
      case OrderStatus.sent:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get _icon {
    final orderStatus = OrderStatus.maybeFrom(status);
    if (orderStatus == null) return Icons.info_outline;
    switch (orderStatus) {
      case OrderStatus.inCart:
        return Icons.shopping_cart_outlined;
      case OrderStatus.pending:
      case OrderStatus.awaitingConfirmation:
        return Icons.hourglass_top;
      case OrderStatus.paymentPending:
      case OrderStatus.pendingPayment:
      case OrderStatus.checkPending:
        return Icons.payment;
      case OrderStatus.approved:
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.completed:
      case OrderStatus.delivered:
      case OrderStatus.sent:
        return Icons.local_shipping_outlined;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  /// Always use our translations for known statuses (e.g. Sent → Yetkazildi).
  String get _text => OrderModel.getStatusDisplayText(status);

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.withValues(alpha: isDark ? 0.15 : 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(_text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final DateTime? date;
  final bool isCompleted;
  final bool isLast;

  const _TimelineStep({required this.title, this.date, required this.isCompleted, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : (isDark ? Colors.white38 : Colors.grey.shade100),
                shape: BoxShape.circle,
                border: Border.all(color: isCompleted ? AppColors.primary : (isDark ? Colors.white : Colors.grey.shade300), width: 2),
              ),
              child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            if (!isLast)
              Container(width: isCompleted?2:1, height: 32, color: isCompleted ? AppColors.primary : (isDark ? Colors.white : Colors.grey.shade200), margin: const EdgeInsets.symmetric(vertical: 2)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted ? Theme.of(context).textTheme.bodyLarge?.color : isDark?AppColors.primaryTextDark:AppColors.primaryText,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(DateFormat('dd.MM.yyyy HH:mm').format(date!), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
                SizedBox(height: isLast ? 0 : 6),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isDiscount;

  const _PriceRow({required this.label, required this.value, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: isDiscount ? Colors.orange : Colors.grey.shade500)),
        Text(
          '${NumberFormat('#,###').format(value)} ₩',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDiscount ? Colors.orange : Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ],
    );
  }
}
