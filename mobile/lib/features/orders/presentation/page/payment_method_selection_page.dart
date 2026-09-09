import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mart/core/constans/app_sizes.dart';
import 'package:mart/features/orders/presentation/page/payment_page.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_info_model.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';

class PaymentMethodSelectionPage extends StatefulWidget {
  final OrderModel order;

  const PaymentMethodSelectionPage({super.key, required this.order});

  @override
  State<PaymentMethodSelectionPage> createState() => _PaymentMethodSelectionPageState();
}

class _PaymentMethodSelectionPageState extends State<PaymentMethodSelectionPage> {
  String _selectedMethod = 'check';

  // Jami summani delivery fee bilan birga hisoblash.
  // Yetkazib berish narxi backenddan keladi (og'irlikka asoslangan tarif) — Flutter buni o'ylab topmaydi.
  double _orderTotalWithDelivery(PaymentInfoModel info) {
    // Agar backend total_amount kelsa (paymentInfo yoki order ichida),
    // uni to'g'ridan-to'g'ri jami summa sifatida ishlatamiz.
    final backendTotal = info.totalAmount ?? widget.order.totalAmount;
    if (backendTotal != null && backendTotal > 0) {
      return backendTotal;
    }

    // Aks holda mahsulotlar summasi + delivery bo'yicha hisoblaymiz.
    final itemsTotal = (widget.order.items ?? [])
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
    final delivery = widget.order.deliveryFee ?? 0;
    return itemsTotal + delivery;
  }

  @override
  void initState() {
    super.initState();
    // API dan to'lov ma'lumotlarini olish (karta raqami, loyalty balans)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderCubit>().getPaymentInfo(widget.order.id ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('checkout_payment_method'.tr()),

        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderSuccess) {
            // Payment ma'lumotlari muvaffaqiyatli keldi
            if (state.paymentInfo != null) {
              return _buildContent(state.paymentInfo!);
            }
            // Hali yuklanyapti
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
            }
            // Xatolik bo'lgan, lekin orders ro'yxati saqlangan
            if (!state.isLoading && state.paymentInfo == null && state.error != null) {
              return _buildErrorState(state.error!);
            }
          }

          if (state is OrderError) {
            return _buildErrorState(state.message);
          }

          return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
        },
      ),
      bottomNavigationBar: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderSuccess && state.paymentInfo != null) {
            return _buildBottomBar(state.paymentInfo!);
          }
          return const SizedBox.shrink();
        },
      ),
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
            ElevatedButton.icon(
              onPressed: () => context.read<OrderCubit>().getPaymentInfo(widget.order.id ?? 0),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text('retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PaymentInfoModel info) {
    // To'lov uchun ishlatiladigan umumiy summa (delivery fee bilan).
    final double orderTotal = _orderTotalWithDelivery(info);
    final double bonusBalance = info.loyaltyBalance ?? 0.0;
    final bool hasBonus = bonusBalance > 0;
    final bool hasSufficientBonus = bonusBalance >= orderTotal;

    // Agar bonus yo'q bo'lsa va bonus tanlangan bo'lsa - check ga qaytarish
    if (!hasBonus && _selectedMethod == 'bonus') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedMethod = 'check');
      });
    }

    return SingleChildScrollView(
      // padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          _buildOrderSummaryCard(info),
          const SizedBox(height: 14),
          _buildBonusCard(bonusBalance, hasBonus, hasSufficientBonus, orderTotal),
          const SizedBox(height: 14),
          _buildPaymentMethods(hasBonus, hasSufficientBonus),
          const SizedBox(height: 14),
          // _buildInstructions(),
          // const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ═══════════════ ORDER SUMMARY ═══════════════

  Widget _buildOrderSummaryCard(PaymentInfoModel info) {
    bool isDark=Theme.of(context).brightness==Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
         ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_details'.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'order'.tr(), value: info.orderNumber ?? '№${info.orderId}'),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'total_amount'.tr(),
            value: '${NumberFormat('#,###').format(_orderTotalWithDelivery(info))} ₩',
            valueStyle: TextStyle(
              fontSize: AppDimens.s20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.primaryTextDark : AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════ BONUS CARD ═══════════════

  Widget _buildBonusCard(double bonusBalance, bool hasBonus, bool hasSufficientBonus, double orderTotal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary, ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'loyalty_card'.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          // Row(
          //   children: [
          //     Container(
          //       padding: const EdgeInsets.all(8),
          //       decoration: BoxDecoration(
          //         color: isDark ? Colors.amber.withOpacity(0.2) : Colors.amber.shade50,
          //         borderRadius: BorderRadius.circular(10),
          //       ),
          //       child: Icon(Icons.card_giftcard, color: Colors.amber.shade700, size: 22),
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       'loyalty_card'.tr(),
          //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('balance'.tr(), style: TextStyle(fontSize: 14, color: isDark?AppColors.primaryTextDark:AppColors.primaryText)),
              Text(
                '${NumberFormat('#,###').format(bonusBalance)} ₩',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark?AppColors.primaryTextDark:AppColors.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasBonus)
            _StatusBanner(icon: Icons.info_outline, text: 'bonus_empty'.tr(), color: Colors.grey)
          else if (hasSufficientBonus)
            _StatusBanner(icon: Icons.check_circle_outline, text: 'bonus_sufficient'.tr(), color: Colors.green)
          else
            _StatusBanner(icon: Icons.info_outline, text: '${'bonus_insufficient'.tr()}\n${'bonus_hybrid_hint'.tr()}', color: Colors.orange),
        ],
      ),
    );
  }

  // ═══════════════ PAYMENT METHODS ═══════════════

  Widget _buildPaymentMethods(bool hasBonus, bool hasSufficientBonus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'checkout_payment_method'.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 16),
          _PaymentOption(
            icon: Assets.icons.noteText,
            title: 'payment_check'.tr(),
            subtitle: 'payment_check_desc'.tr(),
            isSelected: _selectedMethod == 'check',
            onTap: () => setState(() => _selectedMethod = 'check'),
          ),
          const SizedBox(height: 10),
          _PaymentOption(
            icon: Assets.icons.star,
            title: 'payment_bonus'.tr(),
            subtitle: hasBonus
                ? (hasSufficientBonus ? 'payment_bonus_full_desc'.tr() : 'payment_bonus_hybrid_desc'.tr())
                : 'bonus_empty'.tr(),
            isSelected: _selectedMethod == 'bonus',
            isDisabled: !hasBonus,
            onTap: hasBonus ? () => setState(() => _selectedMethod = 'bonus') : null,
            badge: hasBonus && !hasSufficientBonus ? 'payment_hybrid'.tr() : null,
          ),
          const SizedBox(height: AppDimens.s20),
          _buildInstructions(),
        ],
      ),
    );
  }

  // ═══════════════ INSTRUCTIONS ═══════════════

  Widget _buildInstructions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedMethod == 'check' ? 'instruction_check'.tr() : 'instruction_bonus'.tr(),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════ BOTTOM BAR ═══════════════

  Widget _buildBottomBar(PaymentInfoModel info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () => _proceedToPayment(info),
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: Text('next'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  void _proceedToPayment(PaymentInfoModel info) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          order: widget.order,
          paymentInfo: info,
          useBonusPayment: _selectedMethod == 'bonus',
        ),
      ),
    );
  }
}

// ═══════════════════════ HELPER WIDGETS ═══════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: isDark?AppColors.primaryTextDark:AppColors.primaryText)),
        Text(
          value,
          style: valueStyle ?? TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppDimens.s10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500, height: 1.4))),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final String? badge;

  const _PaymentOption({
    required this.icon, required this.title, required this.subtitle,
    required this.isSelected, this.isDisabled = false, this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: isDisabled ? 0.45 : 1.0,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppDimens.s16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
            color: isDark?AppColors.bgSecondaryDark:AppColors.bgSecondary,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:  (isDark ? AppColors.bgMainDark : AppColors.bgMain),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(icon),
                // Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark?AppColors.primaryTextDark:AppColors.primaryText,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text(badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDisabled ? Colors.grey.shade700 : (isDark ? Colors.grey.shade600 : Colors.grey.shade400)),
                    width: isSelected ? 6 : 2,
                  ),
                  color: Theme.of(context).cardColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
