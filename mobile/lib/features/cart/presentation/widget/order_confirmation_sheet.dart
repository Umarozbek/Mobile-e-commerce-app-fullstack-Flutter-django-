import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../locations/data/models/location_model.dart';

class OrderConfirmationSheet extends StatefulWidget {
  final LocationModel selectedLocation;
  final double totalPrice;
  /// Backenddan kelgan yetkazib berish narxi (og'irlikka asoslangan tariff). Flutter buni hisoblamaydi.
  final double deliveryFee;
  final VoidCallback onChangeLocation;
  final Function(String comment) onConfirm;
  final bool isLoading;

  const OrderConfirmationSheet({
    super.key,
    required this.selectedLocation,
    required this.totalPrice,
    this.deliveryFee = 0,
    required this.onChangeLocation,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  State<OrderConfirmationSheet> createState() => _OrderConfirmationSheetState();
}

class _OrderConfirmationSheetState extends State<OrderConfirmationSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgTertiaryDark : Colors.white;
    final cardBg = isDark ? AppColors.bgSecondaryDark : Colors.grey.shade50;
    final borderColor = isDark ? AppColors.borderDark : Colors.grey.shade200;
    final textColor = isDark ? AppColors.primaryTextDark : Colors.black87;
    final labelColor = isDark ? AppColors.secondaryTextDark : Colors.grey.shade600;
    final editBtnBg = isDark ? AppColors.bgTertiaryDark : Colors.white;

    return GestureDetector(
      onTap: () => _commentFocus.unfocus(),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle bar ──
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Sarlavha ──
                Text(
                  'checkout_title'.tr(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Manzil kartasi ──
                _buildSectionLabel('checkout_delivery_address'.tr(), labelColor),
                const SizedBox(height: 10),
                InkWell(
                  onTap: widget.onChangeLocation,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SvgPicture.asset(
                            Assets.icons.location,
                            // color: isDark ? AppColors.primaryDark : AppColors.primary,
                            // size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedLocation.address,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.selectedLocation.active) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'active'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.successVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: editBtnBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            'common_edit'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.primaryDark : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Izoh ──
                _buildSectionLabel('${'checkout_comment'.tr()} (${'comment_optional'.tr()})', labelColor),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  maxLines: 3,
                  minLines: 2,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'comment_hint'.tr(),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.disabledTextDark : Colors.grey.shade400,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Narx tafsiloti ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow(
                        'order_products'.tr(),
                        '${NumberFormat('#,###').format(widget.totalPrice)} ₩',
                        labelColor: labelColor,
                        valueColor: textColor,
                      ),
                      const SizedBox(height: 10),
                      _buildPriceRow(
                        'delivery'.tr(),
                        '${NumberFormat('#,###').format(widget.deliveryFee)} ₩',
                        labelColor: labelColor,
                        valueColor: textColor,
                      ),
                      const Divider(height: 24),
                      _buildPriceRow(
                        'cart_total'.tr(),
                        '${NumberFormat('#,###').format(widget.totalPrice + widget.deliveryFee)} ₩',
                        isBold: true,
                        fontSize: 18,
                        labelColor: labelColor,
                        valueColor: textColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tasdiqlash tugmasi ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.isLoading
                        ? null
                        : () => widget.onConfirm(_commentController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'common_confirm'.tr(),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color labelColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: labelColor,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 15,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize - 2,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: isBold ? valueColor : labelColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
