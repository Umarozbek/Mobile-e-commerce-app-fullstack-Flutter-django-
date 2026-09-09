import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../locations/data/models/location_model.dart';
import '../../../locations/presentation/cubit/location_cubit.dart';
import '../../../locations/presentation/cubit/location_state.dart';
import '../../../locations/presentation/page/add_location_page.dart';
import '../../../locations/presentation/widget/select_location_bottom_sheet.dart';
import '../../../loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/page/orders_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _paymentMethod = 'loyalty_card'; // 'loyalty_card', 'check'
  double? _loyaltyCardBalance;
  File? _checkImage;
  final ImagePicker _picker = ImagePicker();
  bool _useLoyaltyCard = true;
  // bool _useCheck = false; // Removed unused field

  @override
  void initState() {
    super.initState();
    _loadLoyaltyCardBalance();
  }

  void _loadLoyaltyCardBalance() {
    context.read<LoyaltyCardCubit>().getBonusList();
  }

  Future<void> _pickCheckImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _checkImage = File(pickedFile.path);
        });
      }
    } catch (_) {
      // silently ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text('checkout_title'.tr()),
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<LoyaltyCardCubit, LoyaltyCardState>(
            listener: (context, state) {
              if (state is LoyaltyCardSuccess) {
                setState(() {
                  _loyaltyCardBalance = state.data?.balance ?? 0.0;
                });
              }
            },
          ),
        ],
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            if (state is CartSuccess && state.items.isNotEmpty) {
              return BlocBuilder<LocationCubit, LocationState>(
                builder: (context, locationState) {
                  final hasSelectedLocation = locationState is LocationLoaded && 
                      locationState.selectedLocation != null;
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Section
                        _buildLocationSection(),
                        const SizedBox(height: AppDimens.s16),
                        
                        // Payment Method Section
                        _buildPaymentMethodSection(state),
                        const SizedBox(height: AppDimens.s16),
                        
                        // Order Summary
                        _buildOrderSummary(state),
                        const SizedBox(height: AppDimens.s24),
                        
                        // Place Order Button
                        _buildPlaceOrderButton(hasSelectedLocation, state),
                      ],
                    ),
                  );
                },
              );
            }
          
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: AppDimens.s24),
                  Text(
                    'cart_empty_title'.tr(),
                    style: const TextStyle(
                      fontSize: AppDimens.s20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, locationState) {
        List<LocationModel> locations = [];
        LocationModel? selectedLocation;
        
        if (locationState is LocationLoaded) {
          locations = locationState.locations;
          selectedLocation = locationState.selectedLocation;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? AppColors.bgTertiaryDark : Colors.white;
        final titleColor = isDark ? AppColors.primaryTextDark : Colors.black87;
        final iconColor = isDark ? AppColors.primaryTextDark : Colors.black87;
        final fieldBgColor = isDark ? AppColors.bgMainDark : AppColors.lightBackground;
        final fieldBorderColor = isDark ? AppColors.borderDark : Colors.grey.shade200;
        final fieldTextColor = isDark ? AppColors.primaryTextDark : Colors.black87;
        final hintColor = isDark ? AppColors.secondaryTextDark : Colors.grey.shade500;

        return Container(
          padding: const EdgeInsets.all(AppDimens.s16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppDimens.r12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 20, color: iconColor),
                      const SizedBox(width: 8),
                      Text(
                        'checkout_delivery_address'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddLocationPage(),
                        ),
                      ).then((_) {
                        context.read<LocationCubit>().loadLocations();
                      });
                    },
                     style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerRight,
                    ),
                    child: Text(
                      'common_add'.tr(),
                      style: const TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.s12),
              
              // Manzil tanlash qismi
              GestureDetector(
                onTap: () => _showLocationSelector(context, locations, selectedLocation),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: fieldBgColor,
                    borderRadius: BorderRadius.circular(AppDimens.r8),
                    border: Border.all(color: fieldBorderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: selectedLocation == null
                            ? Text(
                                locations.isEmpty 
                                    ? 'add_new_address_prompt'.tr() 
                                    : 'checkout_delivery_address_hint'.tr(),
                                style: TextStyle(
                                  color: hintColor,
                                  fontSize: AppDimens.s14,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedLocation.address,
                                    style: TextStyle(
                                      color: fieldTextColor,
                                      fontSize: AppDimens.s14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (selectedLocation.active) ...[
                                     const SizedBox(height: 2),
                                     Text(
                                      'active'.tr(), 
                                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500)
                                    ),
                                  ]
                                ],
                              ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationSelector(
    BuildContext context, 
    List<LocationModel> locations, 
    LocationModel? selectedLocation,
  ) {
    SelectLocationBottomSheet.show(
      context: context,
      locations: locations,
      selectedLocation: selectedLocation,
      onLocationSelected: (location) {
        context.read<LocationCubit>().selectLocation(location);
      },
      onAddNewLocation: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddLocationPage(),
          ),
        ).then((_) {
          context.read<LocationCubit>().loadLocations();
        });
      },
    );
  }

  Widget _buildPaymentMethodSection(CartSuccess cartState) {
    final total = cartState.totalPrice + cartState.deliveryFee; // subtotal + delivery
    final loyaltyBalance = _loyaltyCardBalance ?? 0.0;
    final remainingAmount = total - loyaltyBalance;
    final hasLoyaltyBalance = loyaltyBalance > 0;
    final canFullyPayWithLoyalty = loyaltyBalance >= total;

    return Container(
      padding: const EdgeInsets.all(AppDimens.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'checkout_payment_method'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppDimens.s16),
          
          // Loyalty Card Section - doim ko'rsatiladi
          _buildLoyaltyCardSection(
            loyaltyBalance: loyaltyBalance,
            total: total,
            hasBalance: hasLoyaltyBalance,
            canFullyPay: canFullyPayWithLoyalty,
          ),


          _buildPaymentOption(
            'card',
            'Loyalty Card orqali',
            Icons.credit_card,
            subtitle: 'Mavjud 5000 ₩',
          ),

          const SizedBox(height: AppDimens.s16),
          
          // Qo'shimcha to'lov kerak bo'lsa yoki loyalty tanlangan bo'lmasa
          if (!canFullyPayWithLoyalty || _paymentMethod == 'check') ...[
            // Check Payment Option
            _buildPaymentOption(
              'check',
              'Check qog\'oz rasmi orqali',
              Icons.receipt_long,
              subtitle: hasLoyaltyBalance && _useLoyaltyCard
                  ? 'Qolgan ${remainingAmount.toStringAsFixed(0)} ₩'
                  : 'To\'liq ${total.toStringAsFixed(0)} ₩',
            ),
          ],
          
          // Check Image Upload (if check selected)
          if (_paymentMethod == 'check') ...[
            const SizedBox(height: AppDimens.s16),
            GestureDetector(
              onTap: _pickCheckImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.s16),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  border: Border.all(
                    color: _checkImage == null
                        ? Colors.grey.shade300
                        : AppColors.primary,
                    width: _checkImage == null ? 1 : 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                      ),
                      child: _checkImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppDimens.r8),
                              child: Image.file(
                                _checkImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.receipt_long,
                              color: AppColors.primary,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: AppDimens.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _checkImage != null
                                ? 'Check rasmini almashtirish'
                                : 'Check rasmini yuklash',
                            style: TextStyle(
                              fontSize: AppDimens.s14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppDimens.s4),
                          Text(
                            'Check qog\'oz rasmini tanlang',
                            style: TextStyle(
                              fontSize: AppDimens.s12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.s8),
                    Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoyaltyCardSection({
    required double loyaltyBalance,
    required double total,
    required bool hasBalance,
    required bool canFullyPay,
  }) {

    final willUseAmount = hasBalance ? (canFullyPay ? total : loyaltyBalance) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimens.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.r12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.s10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimens.r8),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loyalty Card',
                      style: TextStyle(
                        fontSize: AppDimens.s16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppDimens.s2),
                    Text(
                      hasBalance ? 'Balans mavjud' : 'Balans yo\'q',
                      style: TextStyle(
                        fontSize: AppDimens.s12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${loyaltyBalance.toStringAsFixed(0)} ₩',
                    style: const TextStyle(
                      fontSize: AppDimens.s20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Mavjud balans',
                    style: TextStyle(
                      fontSize: AppDimens.s10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppDimens.s16),
          
          // Use loyalty card toggle
          Container(
            padding: const EdgeInsets.all(AppDimens.s12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimens.r8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasBalance 
                            ? 'Loyalty card dan foydalanish'
                            : 'Loyalty card bo\'sh',
                        style: const TextStyle(
                          fontSize: AppDimens.s14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (hasBalance) ...[
                        const SizedBox(height: AppDimens.s4),
                        Text(
                          canFullyPay 
                              ? 'To\'liq to\'lov uchun yetarli'
                              : 'Qisman to\'lov: ${willUseAmount.toStringAsFixed(0)} ₩',
                          style: TextStyle(
                            fontSize: AppDimens.s12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasBalance)
                  Switch(
                    value: _useLoyaltyCard,
                    onChanged: (value) {
                      setState(() {
                        _useLoyaltyCard = value;
                        if (value && canFullyPay) {
                          _paymentMethod = 'loyalty_card';
                        } else {
                          _paymentMethod = 'check';
                        }
                      });
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withValues(alpha: 0.5),
                    inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.s12,
                      vertical: AppDimens.s6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppDimens.r4),
                    ),
                    child: const Text(
                      '0 ₩',
                      style: TextStyle(
                        fontSize: AppDimens.s12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Info message
          if (hasBalance && !canFullyPay && _useLoyaltyCard) ...[
            const SizedBox(height: AppDimens.s12),
            Container(
              padding: const EdgeInsets.all(AppDimens.s10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.r8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 18,
                  ),
                  const SizedBox(width: AppDimens.s8),
                  Expanded(
                    child: Text(
                      'Qolgan ${(total - loyaltyBalance).toStringAsFixed(0)} ₩ ni check orqali to\'lang',
                      style: TextStyle(
                        fontSize: AppDimens.s12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon, {
    String? subtitle,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = value;
          if (value == 'loyalty_card') {
            _useLoyaltyCard = true;
          } else if (value == 'check') {
            // If loyalty card has balance, use both
            if (_loyaltyCardBalance != null && _loyaltyCardBalance! > 0) {
              _useLoyaltyCard = true;
            } else {
              _useLoyaltyCard = false;
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimens.s12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.r8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600),
            const SizedBox(width: AppDimens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppDimens.s16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppDimens.s4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppDimens.s12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartSuccess state) {
    final subtotal = state.totalPrice;
    // Yetkazib berish narxi backenddan keladi (og'irlikka asoslangan tarif) — Flutter buni hisoblamaydi.
    final deliveryFee = state.deliveryFee;
    final total = subtotal + deliveryFee;
    final loyaltyBalance = _loyaltyCardBalance ?? 0.0;
    final loyaltyPayment = _useLoyaltyCard && loyaltyBalance > 0
        ? (loyaltyBalance >= total ? total : loyaltyBalance)
        : 0.0;
    final checkPayment = total - loyaltyPayment;

    return Container(
      padding: const EdgeInsets.all(AppDimens.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_summary'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppDimens.s16),
          _buildSummaryRow('order_products'.tr(), '${subtotal.toStringAsFixed(0)} ₩'),
          const SizedBox(height: AppDimens.s8),
          _buildSummaryRow('delivery'.tr(), '${deliveryFee.toStringAsFixed(0)} ₩'),
          const Divider(height: AppDimens.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cart_total'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} ₩',
                style: const TextStyle(
                  fontSize: AppDimens.s20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          // Payment Breakdown
          if (_useLoyaltyCard && loyaltyPayment > 0) ...[
            const Divider(height: AppDimens.s24),
            const SizedBox(height: AppDimens.s8),
            Container(
              padding: const EdgeInsets.all(AppDimens.s12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(AppDimens.r8),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Loyalty card',
                    '-${loyaltyPayment.toStringAsFixed(0)} ₩',
                    color: Colors.green.shade700,
                  ),
                  if (checkPayment > 0) ...[
                    const SizedBox(height: AppDimens.s8),
                    _buildSummaryRow(
                      'Check orqali',
                      '${checkPayment.toStringAsFixed(0)} ₩',
                      color: Colors.orange.shade700,
                    ),
                  ],
                ],
              ),
            ),
          ] else if (_paymentMethod == 'check') ...[
            const Divider(height: AppDimens.s24),
            const SizedBox(height: AppDimens.s8),
            Container(
              padding: const EdgeInsets.all(AppDimens.s12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(AppDimens.r8),
              ),
              child: _buildSummaryRow(
                'Check orqali',
                '${total.toStringAsFixed(0)} ₩',
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimens.s14,
            color: color ?? Colors.grey.shade700,
            fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppDimens.s14,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }


  void _placeOrder() async {
    final cartState = context.read<CartCubit>().state;
    final locationState = context.read<LocationCubit>().state;
    
    if (cartState is! CartSuccess || locationState is! LocationLoaded) {
      return;
    }
    
    final selectedLocation = locationState.selectedLocation;
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('select_delivery_address_prompt'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Buyurtma yaratish
      await context.read<OrderCubit>().createOrder(
        items: cartState.items,
        deliveryAddress: selectedLocation,
        totalAmount: cartState.totalPrice,
        deliveryFee: cartState.deliveryFee,
      );
      
      // Savatni tozalash
      context.read<CartCubit>().clearCart();
      
      // Muvaffaqiyatli xabar ko'rsatish
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart_order_created'.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Checkout page'dan chiqish
        Navigator.pop(context);
        
        // Buyurtmalar sahifasiga o'tish
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OrdersPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildPlaceOrderButton(bool hasSelectedLocation, CartSuccess cartState) {
    final total = cartState.totalPrice + cartState.deliveryFee;
    final loyaltyBalance = _loyaltyCardBalance ?? 0.0;
    final canFullyPayWithLoyalty = loyaltyBalance >= total;
    
    // Buyurtma qilish shartlari
    bool canPlaceOrder = hasSelectedLocation;
    String? disabledReason;
    
    if (!hasSelectedLocation) {
      disabledReason = 'select_address'.tr();
    } else if (_useLoyaltyCard && canFullyPayWithLoyalty) {
      // Loyalty card bilan to'liq to'lash mumkin
      canPlaceOrder = true;
    } else if (_paymentMethod == 'check' || (!canFullyPayWithLoyalty && _useLoyaltyCard)) {
      // Check kerak
      if (_checkImage == null) {
        canPlaceOrder = false;
        disabledReason = 'upload_receipt_required'.tr();
      }
    } else if (!_useLoyaltyCard && _paymentMethod != 'check') {
      canPlaceOrder = false;
      disabledReason = 'To\'lov usulini tanlang';
    }

    return Column(
      children: [
        if (disabledReason != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.s12),
            margin: const EdgeInsets.only(bottom: AppDimens.s12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(AppDimens.r8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: AppDimens.s8),
                Expanded(
                  child: Text(
                    disabledReason,
                    style: TextStyle(
                      fontSize: AppDimens.s14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canPlaceOrder ? _placeOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppDimens.s16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: AppDimens.s8),
                Text(
                  'checkout_title'.tr(),
                  style: const TextStyle(
                    fontSize: AppDimens.s16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



