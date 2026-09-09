import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/extention/padding_extention.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../locations/data/models/location_model.dart';
import '../../../locations/presentation/cubit/location_cubit.dart';
import '../../../locations/presentation/cubit/location_state.dart';
import '../../../locations/presentation/page/add_location_page.dart';
import '../../../locations/presentation/widget/select_location_bottom_sheet.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/cubit/order_state.dart';
import '../../../orders/presentation/page/orders_page.dart';
import '../../data/models/cart_order_model.dart';
import '../cubit/cart_cubit.dart';
import '../widget/cart_shimmer.dart';
import '../widget/order_confirmation_sheet.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  Future<void> _onRefresh(BuildContext context) async {
    await context.read<CartCubit>().loadCart();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
        title: Text('cart'.tr()),
        elevation: 1,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const CartShimmer();
          }

          if (state is CartError) {
            return RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: Stack(
                children: [
                  ListView(), // For RefreshIndicator
                  CommonErrorWidget(
                    title: 'cart_error_title'.tr(),
                    message: state.message,
                    onRetry: () => context.read<CartCubit>().loadCart(),
                    buttonText: 'cart_retry'.tr(),
                    icon: Icons.error_outline,
                  ),
                ],
              ),
            );
          }

          if (state is CartSuccess) {
            if (state.items.isEmpty) {
              return _buildEmptyState(context);
            }

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _onRefresh(context),
                    child: ListView.builder(
                      // padding: const EdgeInsets.all(AppDimens.s16),
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        return _buildCartItem(
                          context,
                          state.items[index],
                          index,
                        );
                      },
                    ),
                  ),
                ),
                _buildBottomBar(context, state.totalPrice),
              ],
            );
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, OrderProductItem item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin:  EdgeInsets.only(bottom: 10,top:  index==0?10:0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        // borderRadius: BorderRadius.circular(16),

      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.images!.isNotEmpty ? item.images?.first ?? '' : "",
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 90, height: 90, color: isDark ? Colors.grey.shade800 : Colors.grey[100],
              ),
              errorWidget: (context, url, error) => Container(
                width: 90,
                height: 90,
                color: isDark ? Colors.white : Colors.grey[50],
                child: Icon(Icons.image_not_supported, color: isDark ? Colors.grey.shade600 : Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.names?.byLocale(context.locale.languageCode) ?? "",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (item.id != null) {
                          context.read<CartCubit>().removeFromCart(item.id!);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color:isDark?Colors.white: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Text(
                  '${item.quantity ?? ''} ${item.measure ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 12),

                // Price & Quantity Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          '${item.price ?? '0'} ₩',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        if ((item.quantity ?? 1) > 1)
                          Text(
                            '${'cart_total'.tr()}: ${((item.price ?? 0) * (item.quantity ?? 1)).toStringAsFixed(0)} ₩',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),

                    // Quantity Controls
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          _buildQtyBtn(
                            context: context,
                            icon: Icons.remove,
                            onTap: () {
                              if (item.id != null) {
                                context.read<CartCubit>().updateQuantity(
                                  item.id!,
                                  (item.quantity ?? 1).toInt() - 1,
                                  orderId: item.orderId ?? 0,
                                );
                              }
                            },
                          ),
                          Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minWidth: 32),
                            child: Text(
                              '${item.quantity ?? 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          _buildQtyBtn(
                            context: context,
                            icon: Icons.add,
                            onTap: () {
                              if (item.id != null) {
                                context.read<CartCubit>().updateQuantity(
                                  item.id!,
                                  (item.quantity ?? 1).toInt() + 1,
                                  orderId: item.orderId ?? 0,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn({required BuildContext context, required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: isDark ? Colors.white: Colors.black54),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, double totalPrice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.s10)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        spacing: AppDimens.s20,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'cart_total'.tr(),
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(totalPrice)} ₩',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                await _placeOrder(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'cart_place_order'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cartState = context.read<CartCubit>().state;
    var locationState = context.read<LocationCubit>().state;

    if (cartState is! CartSuccess) {
      return;
    }

    // Check if locations are loaded, if not, load them first
    if (locationState is! LocationLoaded) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('cart_loading_addresses'.tr()),
                ],
              ),
            ),
          ),
        ),
      );

      // Load locations
      await context.read<LocationCubit>().loadLocations();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        // Get updated state
        locationState = context.read<LocationCubit>().state;
      } else {
        return;
      }
    }

    // Get locations from loaded state
    final locations = locationState is LocationLoaded ? locationState.locations : <LocationModel>[];
    
    // If no locations, show add location page directly or handle empty state
    if (locations.isEmpty) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddLocationPage(),
          ),
        );
      }
      return;
    }

    // If there ARE locations, ensure one is selected
    if (locationState is LocationLoaded && locationState.selectedLocation == null) {
       // If none selected, select the first one automatically
       if (locations.isNotEmpty) {
         context.read<LocationCubit>().selectLocation(locations.first);
         locationState = context.read<LocationCubit>().state;
       }
    }
    
    if (!context.mounted) return;

    // Show Order Confirmation Sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            final currentLocation = state is LocationLoaded ? state.selectedLocation : null;
            
            // If something happened to location, close sheet
            if (currentLocation == null) {
              Navigator.pop(sheetContext);
              return const SizedBox();
            }

            return BlocBuilder<OrderCubit, OrderState>(
              builder: (context, orderState) {
                final isLoading = orderState is OrderLoading;
                
                return OrderConfirmationSheet(
                   selectedLocation: currentLocation,
                   totalPrice: cartState.totalPrice,
                   deliveryFee: cartState.deliveryFee,
                   isLoading: isLoading,
                   onChangeLocation: () async {
                      // Show location selector ABOVE this sheet or Navigate?
                      // Better to close this sheet, show selector, then re-open confirmation?
                      // Or show selector on top. Let's try showing selector on top.
                      final newLocation = await showModalBottomSheet<LocationModel>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => SelectLocationBottomSheet(
                          locations: locations,
                          selectedLocation: currentLocation,
                          onLocationSelected: (location) {
                            context.read<LocationCubit>().selectLocation(location);
                          },
                          onAddNewLocation: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddLocationPage(),
                              ),
                            );
                          },
                        ),
                      );
                      
                      // If user selected something (not null and not same), it's already updated in Cubit via onLocationSelected callback above
                   },
                   onConfirm: (comment) async {
                      try {
                        // Create order
                        await context.read<OrderCubit>().createOrder(
                          items: cartState.items,
                          deliveryAddress: currentLocation,
                          totalAmount: cartState.totalPrice,
                          deliveryFee: cartState.deliveryFee,
                          comment: comment,
                        );

                        if (!context.mounted) return;

                        // Clear cart
                        context.read<CartCubit>().clearCart();
                        
                        // Close bottom sheet
                        Navigator.pop(sheetContext);

                        // Show success message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('cart_order_created'.tr()),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Navigate to orders page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrdersPage()),
                          );
                        }
                      } catch (e) {
                         // Error handling is done in Cubit (emit OrderError) but we might want to show snackbar here?
                         // Actually OrderCubit emits OrderError, but we are inside builder.
                         // Ideally we should listen to OrderCubit for navigation/snackbar.
                         // But for now, we just catch unexpected errors.
                      }
                   },
                );
              }
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: Stack(
        children: [
          ListView(), // To ensure RefreshIndicator works
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: isDark ? Colors.grey.shade600 : Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'cart_empty_title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'cart_empty_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey.shade500 : Colors.grey[500],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ).paddingSymmetric(horizontal: 24),
          ),
        ],
      ),
    );
  }
}
