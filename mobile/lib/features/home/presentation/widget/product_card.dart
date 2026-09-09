import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mart/core/widgets/universal_button.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/utils/b2b_helper.dart';
import '../../../../core/utils/get_measure.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../../b2b/presentation/cubit/b2b_cubit.dart';
import '../../../cart/data/models/cart_order_model.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../favourites/presentation/cubit/favourites_cubit.dart';
import '../../../product_detail/presentation/page/product_detail_page.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final String? productType;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.productType,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isB2BUser = false;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _checkB2BStatus();
  }

  Future<void> _checkB2BStatus() async {
    final isB2B = await B2BHelper.isB2BUser();
    if (mounted) {
      setState(() {
        _isB2BUser = isB2B;
      });
    }
  }

  /// Cubit dan favourite holatini olish (barcha state turlari uchun ishlaydi)
  bool _getIsFavorite(FavouritesState favState) {
    final productId = widget.product.effectiveId;
    if (productId <= 0) return widget.product.isFavorite ?? false;

    // Har doim cubit dan olish - Loading/Error state da ham to'g'ri ishlaydi
    return context.read<FavouritesCubit>().isFavourite(productId);
  }

  /// Savatda shu mahsulot uchun OrderProductItem topish (miqdor o‘zgartirish / o‘chirish uchun)
  static OrderProductItem? _findCartItem(CartState cartState, int productId) {
    if (cartState is! CartSuccess || productId <= 0) return null;
    for (final item in cartState.items) {
      if (item.productId != null && item.productId == productId) return item;
      if (item.id == productId) return item;
    }
    return null;
  }

  String _getImageUrl() {
    final images = widget.product.product?.images;
    if (images != null && images.isNotEmpty) {
      final url = images.first.image;
      if (url != null && url.trim().isNotEmpty) return url;
    }
    // return 'https://picsum.photos/500/500?random=${widget.product.id}';
    return '';
  }

  /// Sarlavha — faqat API dan: names { uz, ru, en, ko } → joriy til.
  String _getTitle(BuildContext context) {
    final lang = context.locale.languageCode;
    final fromApi = widget.product.names?.byLocale(lang);
    if (fromApi != null && fromApi.trim().isNotEmpty) return fromApi;
    return widget.product.nameUz ??
        widget.product.nameEn ??
        widget.product.nameRu ??
        widget.product.nameKr ??
        widget.product.name ??
        '';
  }

  String _getPrice() {
    // Kartadagi asosiy yirik narx – doim retail narx.
    return _getRegularPrice();
  }

  /// Eski narx — API da chegirma boʻlsa (discount_price yoki discount_percent) hisoblangan.
  String? _getOldPrice() {
    final oldPrice = widget.product.product?.oldPrice;
    final newPrice = widget.product.product?.newPrice ?? widget.product.product?.price?.toString();
    if (oldPrice != null && oldPrice.trim().isNotEmpty && newPrice != null && oldPrice != newPrice) {
      return _formatPrice(oldPrice);
    }
    return null;
  }

  /// Oʻlchov — API da boʻlsa (measure), aks holda boʻsh.
  String _getMeasure() {
    final m = widget.product.product?.measure;
    if (m == null) return '';
    return m.getMeasure();
  }

  bool _hasDiscount() {
    return _getOldPrice() != null;
  }

  double? _getDiscountPercentage() {
    final details = widget.product.product;
    if (details == null) return null;

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // Chegirma foizi faqat retail narxlar bo‘yicha hisoblanadi (B2B emas).
    final double? newPrice = (details.newPrice != null && details.newPrice!.trim().isNotEmpty)
        ? double.tryParse(details.newPrice!)
        : _toDouble(details.price);
    final double? oldPrice = (details.oldPrice != null && details.oldPrice!.trim().isNotEmpty)
        ? double.tryParse(details.oldPrice!)
        : null;

    if (newPrice != null && oldPrice != null && oldPrice > 0 && oldPrice > newPrice) {
      return ((oldPrice - newPrice) / oldPrice * 100);
    }

    return null;
  }

  bool _isNew() {
    return widget.productType == 'newGoods';
  }

  bool _isTop() {
    return widget.productType == 'popularGoods';
  }

  bool _isSale() {
    return widget.productType == 'saleGoods' || _hasDiscount();
  }

  String? _getOptomPrice() {
    num? b2b = widget.product.product?.b2bPrice;
    if (b2b == null && widget.product.variants != null && widget.product.variants!.isNotEmpty) {
      b2b = widget.product.variants!.first.prices?.b2bPrice;
    }

    // B2B narx null yoki 0 (yoki manfiy) bo'lsa, umuman ko'rsatmaymiz
    if (b2b == null || b2b <= 0) return null;
    if (b2b is int) return b2b.toString();
    if (b2b is double && b2b > 0) {
      return b2b.truncateToDouble() == b2b ? b2b.toInt().toString() : b2b.toStringAsFixed(2);
    }
    return b2b.toString();
  }

  /// B2B buyurtma uchun minimal ulgurji miqdor (variant bo'yicha, aks holda product bo'yicha).
  /// Agar hech narsa kelmasa yoki <= 0 bo'lsa, 1 qaytadi.
  int _getMinWholesaleQuantity() {
    final productDetails = widget.product.product;

    // Avval variantlar darajasida tekshiramiz (agar B2B narxni ham variantdan olayotgan bo'lsak)
    if (widget.product.variants != null && widget.product.variants!.isNotEmpty) {
      final firstVariant = widget.product.variants!.first;
      final vMin = firstVariant.prices?.minWholesaleQuantity;
      if (vMin != null && vMin > 0) return vMin;
    }

    // Aks holda product darajasidagi min_wholesale_quantity
    final pMin = productDetails?.minWholesaleQuantity;
    if (pMin != null && pMin > 0) return pMin;

    return 1;
  }

  /// Oddiy narx — API: prices.price (yoki newPrice / oldPrice).
  String _getRegularPrice() {
    final p = widget.product.product;
    // Avval string ko'rinishidagi asosiy narx (newPrice) ni tekshiramiz
    if (p?.newPrice != null && p!.newPrice!.trim().isNotEmpty) {
      final num? n = double.tryParse(p.newPrice!.trim());
      if (n != null && n > 0) return _formatPrice(p.newPrice!);
    }

    // Keyin raqamli price maydonini tekshiramiz
    if (p?.price != null && p!.price! > 0) {
      return _formatPrice(p.price!.toString());
    }

    // Oxirida eski narx (oldPrice) – faqat > 0 bo'lsa
    if (p?.oldPrice != null && p!.oldPrice!.trim().isNotEmpty) {
      final num? n = double.tryParse(p.oldPrice!.trim());
      if (n != null && n > 0) return _formatPrice(p.oldPrice!);
    }

    // Hech qanday haqiqiy narx bo'lmasa, bo'sh string qaytaramiz (0 ko'rsatmaymiz)
    return '';
  }

  String _formatPrice(String value) {
    final num? n = double.tryParse(value);
    if (n == null) return value;
    return n.truncateToDouble() == n ? n.toInt().toString() : n.toStringAsFixed(2);
  }

  void _toggleFavorite(bool currentFavorite) {
    final productId = widget.product.effectiveId;
    if (productId <= 0) return;

    // Cubit will handle optimistic update and trigger rebuild via BlocBuilder
    try {
      final cubit = context.read<FavouritesCubit>();

      if (currentFavorite) {
        cubit.removeFromFavourites(productId: productId);
      } else {
        cubit.addToFavourites(productId: productId, product: widget.product);
      }
    } catch (e) {
      // Error will be handled by cubit's error revert logic
      debugPrint('Error toggling favorite: $e');
    }
  }

  String get _heroTag =>
      'product_image_${widget.product.id}_${widget.productType ?? "default"}';

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailPage(
              product: widget.product,
              heroTag: _heroTag,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavouritesCubit, FavouritesState>(
      buildWhen: (previous, current) {
        final productId = widget.product.effectiveId;
        if (productId <= 0) return false;

        // Faqat shu mahsulot holati o'zgarganda rebuild
        final wasFav = previous is FavouritesSuccess &&
            previous.isFavourite(productId);
        final isFav = current is FavouritesSuccess &&
            current.isFavourite(productId);
        return wasFav != isFav;
      },
      builder: (context, favState) {
        final isFavorite = _getIsFavorite(favState);

        return BlocListener<B2BCubit, B2BState>(
          listener: (context, state) {
            if (state is B2BStatusChecked || state is B2BRegistrationSuccess) {
              _checkB2BStatus();
            }
          },
          child: _buildProductCard(context, isFavorite),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, bool isFavorite) {
    final imageUrl = _getImageUrl();
    final title = _getTitle(context);
    final regularPrice = _getRegularPrice();
    final bool hasPrice = regularPrice.isNotEmpty;
    final oldPrice = _getOldPrice();
    final hasDiscount = _hasDiscount();
    final optomPrice = _getOptomPrice();
    final double? b2bNumeric =
        optomPrice != null ? double.tryParse(optomPrice) : null;
    final bool showB2BPrice =
        _isB2BUser && b2bNumeric != null && b2bNumeric > 0;
    final measure = _getMeasure();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap ?? _navigateToDetail,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.s6,
          vertical: AppDimens.s2,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(AppDimens.s10),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border, strokeAlign: 1, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.s10),
              ),
              child: Stack(
                children: [
                  Hero(
                    tag: _heroTag,
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            ShimmerWidget(
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppDimens.r12),
                              ),
                            ),
                        errorWidget: (context, url, error) =>
                            Container(
                              color: AppColors.lightBackground,
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                                size: 40,
                              ),
                            ),
                      )
                          : Container(
                        color: AppColors.lightBackground,
                        child: Icon(
                          Icons.image,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  // Favourite Heart Icon with tap handler
                  Positioned(
                    top: AppDimens.s5,
                    right: AppDimens.s5,
                    child: GestureDetector(
                      onTap: () {
                        // Toggle favourite using cubit
                        _toggleFavorite(isFavorite);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppDimens.s4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: isFavorite
                              ? Colors.red
                              : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // B2B narx bejigi – faqat B2B foydalanuvchi va b2b narx > 0 bo'lsa
                  // if (showB2BPrice)
                  //   Positioned(
                  //     top: AppDimens.s5,
                  //     left: AppDimens.s5,
                  //     child: Container(
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: AppDimens.s6,
                  //         vertical: AppDimens.s2,
                  //       ),
                  //       decoration: BoxDecoration(
                  //         color: Colors.black.withOpacity(0.6),
                  //         borderRadius: BorderRadius.circular(AppDimens.s4),
                  //       ),
                  //       child: Text(
                  //         '${'b2b_price_label'.tr()}: $optomPrice ₩',
                  //         style: const TextStyle(
                  //           fontSize: AppDimens.s10,
                  //           fontWeight: FontWeight.w600,
                  //           color: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // Badges: New, Top, Discount
                  Positioned(
                    bottom: AppDimens.s5,
                    left: AppDimens.s5,
                    child: Row(
                      children: [
                        if (_isNew())
                          Container(
                            margin: const EdgeInsets.only(right: AppDimens.s4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.s6,
                              vertical: AppDimens.s2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(AppDimens.s4),
                            ),
                            child: Text(
                              'new'.tr().toUpperCase(),
                              style: const TextStyle(
                                fontSize: AppDimens.s10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (_isTop())
                          Container(
                            margin: const EdgeInsets.only(right: AppDimens.s4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.s6,
                              vertical: AppDimens.s2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(AppDimens.s4),
                            ),
                            child: Text(
                              'top'.tr().toUpperCase(),
                              style: const TextStyle(
                                fontSize: AppDimens.s10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        // if (_isSale() && _getDiscountPercentage() != null)
                        //   Container(
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: AppDimens.s6,
                        //       vertical: AppDimens.s2,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: Colors.red,
                        //       borderRadius: BorderRadius.circular(AppDimens.s4),
                        //     ),
                        //     child: Text(
                        //       '-${_getDiscountPercentage()!.toStringAsFixed(
                        //           0)}%',
                        //       style: const TextStyle(
                        //         fontSize: AppDimens.s10,
                        //         fontWeight: FontWeight.bold,
                        //         color: Colors.white,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            // Product Info
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.s10),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppDimens.s5,),
                    // Title
                    Text(
                      title.isNotEmpty ? title : 'mahsulot'.tr(),
                      style: TextStyle(
                        fontSize: AppDimens.s12,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.secondaryTextDark : AppColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Retail narx (asosiy) + agar mavjud bo'lsa B2B narxi (oltin rangda)
                    if (hasPrice)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$regularPrice ₩',
                            style: TextStyle(
                              fontSize: (hasDiscount && oldPrice != null) ? 18 : (showB2BPrice?AppDimens.s16:AppDimens.s20),
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.primaryTextDark : AppColors.primaryText,
                            ),
                          ),
                          if (showB2BPrice) ...[
                            const SizedBox(width: AppDimens.s6),
                            Text(
                              '/',
                              style: TextStyle(
                                fontSize: (hasDiscount && oldPrice != null) ? 16 : (showB2BPrice?AppDimens.s15:AppDimens.s16),
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.primaryTextDark : AppColors.primaryText,
                              ),
                            ),
                            Text(
                              '$optomPrice ₩',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(

                                fontSize: AppDimens.s14,
                                fontWeight: FontWeight.w700,
                                // Light mode: orange, Dark mode: gold
                                color: isDark ? AppColors.loyaltyCardGradientStart : AppColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (hasDiscount && oldPrice != null && hasPrice)
                      Row(
                        children: [
                          Text(
                            '$oldPrice ₩',
                            style: TextStyle(
                              fontSize: AppDimens.s14,
                              fontWeight: FontWeight.w400,
                              color: isDark ? AppColors.secondaryTextDark : AppColors.secondaryText,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (_getDiscountPercentage() != null)
                            Text(
                              ' / ${_getDiscountPercentage()!.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: AppDimens.s12,
                                fontWeight: FontWeight.w400,
                                color: Colors.green,
                              ),
                            )
                        ],
                      ),

                    if (hasDiscount && oldPrice != null)
                    SizedBox(height: AppDimens.s2,),
                    if (!(hasDiscount && oldPrice != null))
                    Divider(color: isDark ? AppColors.borderDark : AppColors.border,),
                    BlocBuilder<CartCubit, CartState>(
                      buildWhen: (prev, next) {
                        if (prev is CartSuccess && next is CartSuccess) {
                          final prevItem = _findCartItem(prev, widget.product.effectiveId);
                          final nextItem = _findCartItem(next, widget.product.effectiveId);
                          return prev.items.length != next.items.length ||
                              (prevItem?.quantity ?? 0) != (nextItem?.quantity ?? 0);
                        }
                        return true;
                      },
                      builder: (context, cartState) {
                        final productId = widget.product.effectiveId;
                        final cartItem = _findCartItem(cartState, productId);
                        final isInCart = cartItem != null && (cartItem.quantity ?? 0) > 0;
                        final qty = cartItem?.quantity ?? 0;

                        if (!isInCart) {
                          return UniversalButton.filled(
                            cornerRadius: AppDimens.r12,
                            backgroundColor: AppColors.primary,
                            height: AppDimens.s40,
                            text: '',
                            onPressed: _isAddingToCart
                                ? null
                                : () async {
                                    if (productId <= 0) return;
                                    setState(() => _isAddingToCart = true);

                                    // Agar B2B narx mavjud bo'lsa va foydalanuvchi B2B bo'lsa,
                                    // minimal ulgurji miqdordan kam buyurtma qilmaslik uchun
                                    final int minQty = _getMinWholesaleQuantity();
                                    final int qty = (showB2BPrice && minQty > 1) ? minQty : 1;

                                    await context
                                        .read<CartCubit>()
                                        .addToCart(widget.product, quantity: qty);

                                    if (!mounted) return;
                                    setState(() => _isAddingToCart = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('success'.tr()),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                            child: _isAddingToCart
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: AppDimens.s8,
                                    children: [
                                       SvgPicture.asset(Assets.icons.shoppingCart,color: Colors.white,),
                                      Text('to_cart'.tr()),
                                    ],
                                  ),
                          );
                        }

                        // Savatda: miqdorni oshirish / kamaytirish
                        return Center(
                          child: Container(
                            height: AppDimens.s40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppDimens.r12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () {
                                    if (cartItem.id == null) return;
                                    if (qty > 1) {
                                      context.read<CartCubit>().updateQuantity(
                                        cartItem.id!,
                                        qty - 1,
                                        orderId: cartItem.orderId,
                                      );
                                    } else {
                                      context.read<CartCubit>().removeFromCart(cartItem.id!);
                                    }
                                  },
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(36, 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '$qty',
                                    textAlign: TextAlign.center,
                                    style:  TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark?AppColors.primaryTextDark:AppColors.primaryText,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () {
                                    if (cartItem.id == null) return;
                                    context.read<CartCubit>().updateQuantity(
                                      cartItem.id!,
                                      qty + 1,
                                      orderId: cartItem.orderId,
                                    );
                                  },
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(36, 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    SizedBox(height: AppDimens.s5,),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
