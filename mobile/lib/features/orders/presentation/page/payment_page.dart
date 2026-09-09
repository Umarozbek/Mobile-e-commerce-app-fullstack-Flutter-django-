import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constans/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_info_model.dart';
import '../../../loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';

class PaymentPage extends StatefulWidget {
  final OrderModel order;
  final PaymentInfoModel paymentInfo;
  final bool useBonusPayment;

  const PaymentPage({
    super.key,
    required this.order,
    required this.paymentInfo,
    this.useBonusPayment = false,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _checkImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // Yetkazib berish narxi backenddan keladi (og'irlikka asoslangan tarif) — Flutter buni o'ylab topmaydi.
  double get _deliveryFee => widget.order.deliveryFee ?? 0;

  // To'lov uchun jami summa — total_amount + delivery fee.
  double get _orderTotal {
    // Agar backend total_amount (paymentInfo yoki order ichida) kelsa,
    // uni to'g'ridan-to'g'ri jami summa sifatida ishlatamiz.
    final backendTotal = widget.paymentInfo.totalAmount ?? widget.order.totalAmount;
    if (backendTotal != null && backendTotal > 0) {
      return backendTotal;
    }

    // Aks holda mahsulotlar summasi + delivery bo'yicha hisoblaymiz.
    final itemsTotal = (widget.order.items ?? [])
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
    return itemsTotal + _deliveryFee;
  }
  double get _loyaltyBalance => widget.paymentInfo.loyaltyBalance ?? 0.0;
  double get _bonusToUse => widget.useBonusPayment
      ? (_loyaltyBalance >= _orderTotal ? _orderTotal : _loyaltyBalance)
      : 0.0;
  double get _remainingAmount => _orderTotal - _bonusToUse;
  bool get _isFullBonusPayment => widget.useBonusPayment && _loyaltyBalance >= _orderTotal;
  bool get _needsCheck => !_isFullBonusPayment;

  Future<void> _pickCheckImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) setState(() => _checkImage = File(pickedFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error'.tr()}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitPayment() async {
    if (_needsCheck && _checkImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('upload_receipt_required'.tr()), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await context.read<OrderCubit>().submitPayment(
      orderId: widget.order.id ?? 0,
      checkImage: _checkImage,
      loyaltyAmount: _bonusToUse > 0 ? _bonusToUse : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('make_payment'.tr()),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
      ),
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, state) {
          if (_isSubmitting) {
            // Muvaffaqiyatli to'lov
            if (state is OrderSuccess && !state.isLoading && state.error == null) {
              // Orders ro'yxatini qaytishda yangilash uchun majburan reload qilamiz
              context.read<OrderCubit>().getOrders();
              // Loyalty balansini backenddan qayta yuklaymiz (masalan, loyalty
              // orqali to'langan bo'lsa, balans backendda allaqachon o'zgargan).
              // Bonus summasini Flutter hech qachon o'zi hisoblamaydi.
              context.read<LoyaltyCardCubit>().loadLoyaltyData(forceRefresh: true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('payment_submitted'.tr()), backgroundColor: Colors.green),
              );
              int count = 0;
              Navigator.of(context).popUntil((_) => count++ >= 3);
              setState(() => _isSubmitting = false);
            }
            // Xatolik: OrderSuccess ichida error yoki OrderError holati
            else if ((state is OrderSuccess && state.error != null) || state is OrderError) {
              setState(() => _isSubmitting = false);
              final message = state is OrderError ? state.message : (state as OrderSuccess).error ?? '';
              if (message.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${'error'.tr()}: $message'), backgroundColor: Colors.red),
                );
              }
            }
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPriceSummary(),
              const SizedBox(height: 14),

              if (widget.useBonusPayment) ...[
                _buildBonusBreakdown(),
                const SizedBox(height: 14),
              ],

              if (_needsCheck) ...[
                _buildPaymentInstructions(),
                const SizedBox(height: 14),
                _buildCheckUpload(),
              ],

              if (_isFullBonusPayment) _buildFullBonusInfo(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ═══════════════ PRICE SUMMARY ═══════════════

  Widget _buildPriceSummary() {
    bool isDark=Theme.of(context).brightness==Brightness.dark;
    final info = widget.paymentInfo;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_details'.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                info.orderNumber ?? '№${info.orderId}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.secondaryTextDark : Colors.grey.shade600,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(_orderTotal)} ₩',
                style:  TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark?AppColors.primaryTextDark:AppColors.primaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════ BONUS BREAKDOWN ═══════════════

  Widget _buildBonusBreakdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment_breakdown'.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.stars, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text('payment_bonus'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                    ]),
                    Text('${NumberFormat('#,###').format(_bonusToUse)} ₩',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
                  ],
                ),
                if (_remainingAmount > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Colors.green.shade200, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.receipt_long, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text('payment_check'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                      ]),
                      Text('${NumberFormat('#,###').format(_remainingAmount)} ₩',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.orange.shade700)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════ PAYMENT INSTRUCTIONS (API dan karta) ═══════════════

  Widget _buildPaymentInstructions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = widget.paymentInfo;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'payment_instruction_text'.tr(),
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildCardInfoRow('card_number'.tr(), info.bankCardNumber ?? '416-069081-01-014'),
          const Divider(),
          _buildCardInfoRow('card_holder'.tr(), info.bankCardHolder ?? 'KODIROV FARRUKH'),
        ],
      ),
    );
  }

  Widget _buildCardInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.secondaryTextDark : Colors.grey.shade600;
    final valueColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? AppColors.primaryTextDark : null);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 13, color: labelColor))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor))),
      ],
    );
  }

  // ═══════════════ CHECK UPLOAD ═══════════════

  Widget _buildCheckUpload() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? AppColors.primaryTextDark : AppColors.primaryText);
    final hintColor = isDark ? AppColors.secondaryTextDark : AppColors.secondaryText;
    final borderColor = isDark ? AppColors.borderDark : Colors.grey.shade300;
    final placeholderBg = isDark ? AppColors.bgSecondaryDark : Colors.grey.shade50;
    final iconColor = isDark ? AppColors.secondaryTextDark : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'upload_receipt'.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 14),
          if (_checkImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_checkImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickCheckImage,
                icon: Icon(Icons.refresh, size: 18, color: isDark ? AppColors.primaryDark : AppColors.primary),
                label: Text('change_image'.tr(), style: TextStyle(color: isDark ? AppColors.primaryDark : AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: isDark ? AppColors.primaryDark : AppColors.primary),
                ),
              ),
            ),
          ] else
            InkWell(
              onTap: _pickCheckImage,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                  color: placeholderBg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 44, color: iconColor),
                    const SizedBox(height: 10),
                    Text(
                      'tap_to_upload'.tr(),
                      style: TextStyle(fontSize: 14, color: hintColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'select_from_gallery'.tr(),
                      style: TextStyle(fontSize: 12, color: iconColor),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════ FULL BONUS INFO ═══════════════

  Widget _buildFullBonusInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.green.withOpacity(0.3) : Colors.green.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: isDark ? Colors.green.shade300 : Colors.green.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'payment_bonus_full_desc'.tr(),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.green.shade200 : Colors.green.shade800, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════ BOTTOM BAR ═══════════════

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSubmit = _isFullBonusPayment || _checkImage != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.06),
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
            onPressed: _isSubmitting ? null : (canSubmit ? _submitPayment : null),
            icon: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_isFullBonusPayment ? Icons.stars : Icons.send, size: 20),
            label: Text(
              _isSubmitting
                  ? 'common_loading'.tr()
                  : (_isFullBonusPayment ? 'pay_with_bonus'.tr() : 'submit_payment'.tr()),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: canSubmit ? AppColors.primary : (isDark ? AppColors.borderDark : Colors.grey.shade300),
              foregroundColor: canSubmit ? Colors.white : (isDark ? AppColors.secondaryTextDark : Colors.grey.shade500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}
