import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order_status.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import 'order_detail_page.dart';

/// Segment: Faollar (active) or Barchasi (all).
enum _OrdersSegment { active, all }

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  _OrdersSegment _segment = _OrdersSegment.active;
  final ScrollController _scrollController = ScrollController();

  List<OrderModel> _applyFilter(List<OrderModel> orders) {
    if (_segment == _OrdersSegment.all) return orders;
    // Faollar: only active (exclude cancelled, delivered, completed, sent)
    final inactiveStatuses = [
      OrderStatus.cancelled,
      OrderStatus.completed,
      OrderStatus.delivered,
      OrderStatus.sent,
    ];
    return orders.where((order) {
      final status = OrderStatus.maybeFrom(order.status);
      if (status == null) return true;
      return !inactiveStatuses.contains(status);
    }).toList();
  }

  Widget _buildSegmentControl() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ?AppColors.bgSecondaryDark : AppColors.bgSecondary;
    final selectedBg = isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary;
    final selectedText = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final unselectedText = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTab(
              label: 'active_orders'.tr(),
              isSelected: _segment == _OrdersSegment.active,
              selectedBg: selectedBg,
              selectedText: selectedText,
              unselectedText: unselectedText,
              onTap: () => setState(() => _segment = _OrdersSegment.active),
            ),
          ),
          Expanded(
            child: _SegmentTab(
              label: 'all_orders'.tr(),
              isSelected: _segment == _OrdersSegment.all,
              selectedBg: selectedBg,
              selectedText: selectedText,
              unselectedText: unselectedText,
              onTap: () => setState(() => _segment = _OrdersSegment.all),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().getOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<OrderCubit>().state;
    if (state is! OrderSuccess) return;
    if (!state.hasMore || state.isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      context.read<OrderCubit>().loadMoreOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('my_orders'.tr()),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return _buildShimmerLoading();
          }

          if (state is OrderSuccess) {
            // Backend'dan qayta yuklash jarayonida (masalan, to'lovdan qaytganda)
            // har doim skeleton loading ko'rsatamiz.
            if (state.isLoading) {
              return _buildShimmerLoading();
            }

            if (state.orders.isEmpty) return _buildEmptyState();

            final filteredOrders = _applyFilter(state.orders);
            final hasMore = state.hasMore;
            final isLoadingMore = state.isLoadingMore;
            final itemCount = filteredOrders.length + 1 + (hasMore ? 1 : 0);

            return RefreshIndicator(
              onRefresh: () => context.read<OrderCubit>().getOrders(),
              color: AppColors.primary,
              child: filteredOrders.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        _buildSegmentControl(),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'no_orders_title'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildSegmentControl();
                        }
                        if (index >= filteredOrders.length + 1) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: isLoadingMore
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }
                        final order = filteredOrders[index - 1];
                        return _OrderCard(order: order);
                      },
                    ),
            );
          }

          if (state is OrderError) {
            return RefreshIndicator(
              onRefresh: () => context.read<OrderCubit>().getOrders(),
              child: Stack(
                children: [
                   ListView(), // For RefreshIndicator
                   CommonErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<OrderCubit>().getOrders(),
                  ),
                ],
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final containerColor = isDark ? Colors.grey.shade900 : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 130,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 120, height: 16, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
                    Container(width: 80, height: 24, decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(12))),
                  ],
                ),
                const Spacer(),
                Container(width: 180, height: 12, decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                Container(width: 100, height: 20, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () => context.read<OrderCubit>().getOrders(),
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'no_orders_title'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'no_orders_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'pull_to_refresh'.tr(),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── ORDER CARD ───────────────

/// Segment tab for Faollar / Barchasi.
class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedBg;
  final Color selectedText;
  final Color unselectedText;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.selectedBg,
    required this.selectedText,
    required this.unselectedText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? selectedBg : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedText : unselectedText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final needsPayment = order.status == 'pending_payment' ||
        order.status == 'payment_pending' ||
        order.status == 'check_pending';

    final items = order.items ?? [];
    final totalQty = items.fold<int>(0, (s, i) => s + i.quantity);
    final itemsTotal = items.fold<double>(0, (s, i) => s + i.totalPrice);
    final dateStr = order.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(order.createdAt!)
        : '—';
    final orderNumber = order.orderNumber ?? 'ORD${order.id}';

    // Narxni delivery fee bilan birga ko'rsatamiz.
    // Yetkazib berish narxi backenddan keladi (og'irlikka asoslangan tarif) — Flutter buni o'ylab topmaydi.
    final delivery = order.deliveryFee ?? 0;

    // Agar backend total_amount kelsa, uni ishonib ishlatamiz.
    // Aks holda mahsulotlar summasi + delivery orqali hisoblaymiz.
    final backendTotal = order.totalAmount;
    final totalWithDelivery = (backendTotal != null && backendTotal > 0)
        ? backendTotal
        : itemsTotal + delivery;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   if (!isDark)
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.06),
        //       blurRadius: 10,
        //       offset: const Offset(0, 4),
        //     ),
        // ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderDetailPage(orderId: order.id!)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID + Status pill
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        orderNumber,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(status: order.status ?? ''),
                  ],
                ),
                const SizedBox(height: 16),
                // Mahsulot / Soni / Sana rows
                // _DetailRow(
                //   label: 'product_label'.tr(),
                //   value: firstProductName,
                // ),
                // const SizedBox(height: 8),
                _DetailRow(
                  label: 'quantity_short'.tr(),
                  value: 'items_count'.tr(args: [totalQty.toString()]),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'date_label'.tr(),
                  value: dateStr,
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
                const SizedBox(height: 14),
                // Narxi + sum
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'price'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark?AppColors.secondaryTextDark:AppColors.secondaryText,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(totalWithDelivery)} ₩',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                if(needsPayment)
                const SizedBox(height: 16),
                if(needsPayment)
                // Full-width button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OrderDetailPage(orderId: order.id!)),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: needsPayment ? AppColors.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade600),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      needsPayment ? 'make_payment_btn'.tr() : 'details'.tr(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark?AppColors.secondaryTextDark:AppColors.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─────────────── STATUS BADGE ───────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _color {
    final orderStatus = OrderStatus.maybeFrom(status);

    if (orderStatus == null) {
      return Colors.grey;
    }

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

    if (orderStatus == null) {
      return Icons.info_outline;
    }

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

  String get _statusText {
    final orderStatus = OrderStatus.maybeFrom(status);

    if (orderStatus == null) {
      return status;
    }

    return orderStatus.translationKey.tr();
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            _statusText,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
