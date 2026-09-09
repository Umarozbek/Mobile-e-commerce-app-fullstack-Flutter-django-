import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/constans/app_text_styles.dart';
import '../../../../core/utils/b2b_helper.dart';
import '../../../../core/utils/get_measure.dart';
import '../../../b2b/presentation/cubit/b2b_cubit.dart';
import '../../../cart/data/models/cart_order_model.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/page/cart_page.dart';
import '../../../favourites/presentation/cubit/favourites_cubit.dart';
import '../../../home/data/models/product_model.dart' as home_models;
import '../../../home/data/models/product_model.dart' show ProductModel, ProductVariant;

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;
  final String? heroTag;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.heroTag,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;
  bool _isB2BUser = false;
  int _quantity = 1;
  bool _isActionLoading = false;
  int? _selectedVariantId;
  final CarouselSliderController _carouselSliderController = CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _checkB2BStatus();
    _selectInitialVariant();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQuantityFromCart();
    });
  }

  // ─────────────────────────── HELPERS ───────────────────────────

  /// Cart ichidan hozirgi tanlangan variant/product ni topish
  OrderProductItem? _findCartItem(CartState cartState) {
    if (cartState is! CartSuccess) return null;

    final targetId = _getActiveProductId();
    if (targetId <= 0) return null;

    // 1. productId bo'yicha qidirish (eng ishonchli)
    for (final item in cartState.items) {
      if (item.productId != null && item.productId == targetId) return item;
    }
    // 2. id bo'yicha qidirish (fallback)
    for (final item in cartState.items) {
      if (item.id == targetId) return item;
    }
    return null;
  }

  /// Hozirgi tanlangan variant yoki asosiy product ning ID si
  int _getActiveProductId() {
    final variant = _getSelectedVariant();
    if (variant != null && variant.id != null) return variant.id!;
    return widget.product.effectiveId;
  }

  /// Cart bilan miqdorni sinxronlashtirish
  void _syncQuantityFromCart() {
    final cartItem = _findCartItem(context.read<CartCubit>().state);
    if (cartItem != null) {
      setState(() => _quantity = cartItem.quantity ?? 1);
    } else {
      // Cartda yo'q bo'lsa, agar mahsulotda B2B narx bo'lsa minimal ulgurji miqdor bilan boshlaymiz
      final int minQty = _getMinWholesaleQuantityForActive();
      final bool hasB2BPrice = _isB2BUser && _getB2BPrice() != null;
      final int target = (hasB2BPrice && minQty > 1) ? minQty : 1;

      if (_quantity != target) {
        setState(() => _quantity = target);
      }
    }
  }

  Future<void> _checkB2BStatus() async {
    final isB2B = await B2BHelper.isB2BUser();
    if (mounted) setState(() => _isB2BUser = isB2B);
  }

  void _selectInitialVariant() {
    final variants = widget.product.variants;
    if (variants == null || variants.isEmpty) return;

    // Asosiy variantni topish, topilmasa birinchisini tanlash
    final mainVariant = variants.where((v) => v.main == true).firstOrNull;
    _selectedVariantId = mainVariant?.id ?? variants.first.id;
  }

  ProductVariant? _getSelectedVariant() {
    final variants = widget.product.variants;
    if (variants == null || _selectedVariantId == null) return null;
    return variants.where((v) => v.id == _selectedVariantId).firstOrNull;
  }

  void _selectVariant(int? variantId) {
    if (variantId == _selectedVariantId) return;
    setState(() {
      _selectedVariantId = variantId;
      _currentImageIndex = 0;
      _quantity = 1;
    });
    // Yangi variant cart da bor-yo'qligini tekshirish
    _syncQuantityFromCart();
  }

  // ─────────── DISPLAY DATA (variant yoki product dan) ───────────

  /// Joriy til kodi
  String get _lang => context.locale.languageCode;

  String _getDisplayName() {
    final v = _getSelectedVariant();
    if (v?.names != null) return v!.names!.byLocale(_lang) ?? widget.product.names?.byLocale(_lang) ?? '';
    return widget.product.names?.byLocale(_lang) ?? '';
  }

  String _getDisplayPrice() {
    final v = _getSelectedVariant();
    if (v?.prices?.retailNew != null) {
      final num val = v!.prices!.retailNew!;
      if (val > 0) return val.toString();
    }
    final p = widget.product.product;
    if (p?.newPrice != null && p!.newPrice!.isNotEmpty) {
      final num? val = double.tryParse(p.newPrice!);
      if (val != null && val > 0) return p.newPrice!;
    }
    if (p?.price != null && p!.price! > 0) return p.price!.toString();
    if (p?.oldPrice != null && p!.oldPrice!.isNotEmpty) {
      final num? val = double.tryParse(p.oldPrice!);
      if (val != null && val > 0) return p.oldPrice!;
    }
    // Hech qanday haqiqiy narx bo'lmasa, bo'sh string qaytaramiz
    return '';
  }

  /// B2B foydalanuvchi uchun ko'rsatiladigan yakuniy narx
  /// (agar mavjud bo'lsa B2B narx, aks holda oddiy retail narx).
  String _getEffectivePrice() {
    final retail = _getDisplayPrice();
    final b2b = _getB2BPrice();
    if (_isB2BUser && b2b != null && b2b.isNotEmpty) {
      return b2b;
    }
    return retail;
  }

  /// Hisob-kitoblar uchun raqamli (num) narx:
  /// - Agar B2B bo'lsa va variant/product uchun b2b narx bo'lsa, o'sha olinadi
  /// - Aks holda variant/product ning retail narxi olinadi
  num _getUnitPriceValue() {
    final v = _getSelectedVariant();
    if (v != null && v.prices != null) {
      final prices = v.prices!;
      // B2B foydalanuvchi uchun avval B2B narx (faqat > 0 bo'lsa)
      if (_isB2BUser && prices.b2bPrice != null && prices.b2bPrice! > 0) {
        return prices.b2bPrice!;
      }
      // Oddiy retail narx
      if (prices.retailNew != null) return prices.retailNew!;
      if (prices.retailOld != null) return prices.retailOld!;
    }

    final p = widget.product.product;
    if (p != null) {
      // B2B foydalanuvchi uchun product darajasidagi B2B narx (faqat > 0 bo'lsa)
      if (_isB2BUser && p.b2bPrice != null && p.b2bPrice! > 0) {
        return p.b2bPrice!;
      }

      // Avval string ko'rinishdagi yangi (asosiy) narxni (newPrice) parse qilamiz
      final newPrice = double.tryParse(p.newPrice ?? '');
      if (newPrice != null) return newPrice;

      // Agar newPrice yo'q bo'lsa, asosiy raqamli price maydoni
      if (p.price != null) return p.price!;

      // Oxirgi navbatda eski narxni (oldPrice) parse qilamiz
      final oldPrice = double.tryParse(p.oldPrice ?? '');
      if (oldPrice != null) return oldPrice;
    }

    return 0;
  }

  String? _getOldPrice() {
    final v = _getSelectedVariant();
    if (v?.prices?.retailOld != null) return v!.prices!.retailOld!.toString();
    return widget.product.product?.oldPrice;
  }

  String _getDisplayDescription() {
    final v = _getSelectedVariant();
    if (v?.descriptions != null) return v!.descriptions!.byLocale(_lang) ?? '';
    return widget.product.product?.descriptions?.byLocale(_lang) ?? '';
  }

  int _getDisplayBonus() {
    final v = _getSelectedVariant();
    return v?.bonus ?? widget.product.product?.bonus ?? 0;
  }

  int _getAvailableStock() {
    final v = _getSelectedVariant();
    return v?.availableQuantity ?? widget.product.product?.availableQuantity ?? 0;
  }

  String? _getB2BPrice() {
    final v = _getSelectedVariant();
    final num? variantB2B = v?.prices?.b2bPrice;
    if (variantB2B != null && variantB2B > 0) {
      return variantB2B.toString();
    }

    final num? productB2B = widget.product.product?.b2bPrice;
    if (productB2B != null && productB2B > 0) {
      return productB2B.toString();
    }

    // Agar B2B narx yo'q yoki 0/<=0 bo'lsa, umuman ko‘rsatmaymiz
    return null;
  }

  /// Joriy mahsulot/variant uchun minimal ulgurji miqdor.
  /// - Avval variant.prices.minWholesaleQuantity
  /// - Aks holda product.minWholesaleQuantity
  /// - Agar hech narsa bo'lmasa yoki <= 0 bo'lsa, 1
  int _getMinWholesaleQuantityForActive() {
    final v = _getSelectedVariant();
    final int? variantMin = v?.prices?.minWholesaleQuantity;
    if (variantMin != null && variantMin > 0) return variantMin;

    final int? productMin = widget.product.product?.minWholesaleQuantity;
    if (productMin != null && productMin > 0) return productMin;

    return 1;
  }

  /// Chegirma foizi: faqat eski/yangi narxlardan hisoblanadi
  /// (backenddan keladigan discount_percent / sale_percent inobatga olinmaydi).
  int? _getDiscountPercent() {
    final oldStr = _getOldPrice();
    final newVal = double.tryParse(_getDisplayPrice());
    if (oldStr != null && oldStr.trim().isNotEmpty && newVal != null && newVal > 0) {
      final oldVal = double.tryParse(oldStr);
      if (oldVal != null && oldVal > newVal) {
        return ((oldVal - newVal) / oldVal * 100).round();
      }
    }
    return null;
  }

  List<home_models.ProductImage> _getImages() {
    final v = _getSelectedVariant();
    if (v != null && v.images != null && v.images!.isNotEmpty) {
      return v.images!.map((url) => home_models.ProductImage(image: url)).toList();
    }
    return widget.product.product?.images ?? [];
  }

  /// Tanlangan variant yoki product o‘lchovi (kg, dona, l, paket yoki measureLabel).
  String _getDisplayMeasureStr() {
    final v = _getSelectedVariant();
    final product = widget.product.product;
    if (v?.measureLabel != null && (v!.measureLabel ?? '').isNotEmpty) {
      return v.measureLabel!;
    }
    if (v?.measure != null) {
      return v!.measure!.getMeasure();
    }
    return product?.measure?.getMeasure() ?? '';
  }

  // ───────────────────── FAVOURITES ─────────────────────

  bool _getIsFavorite(FavouritesState favState) {
    final productId = widget.product.effectiveId;
    if (productId <= 0) return widget.product.isFavorite ?? false;

    // Har doim cubit dan olish - Loading/Error state da ham to'g'ri ishlaydi
    return context.read<FavouritesCubit>().isFavourite(productId);
  }

  void _toggleFavorite(bool currentFavorite) {
    final productId = widget.product.effectiveId;
    if (productId <= 0) return;

    final cubit = context.read<FavouritesCubit>();
    if (currentFavorite) {
      cubit.removeFromFavourites(productId: productId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product_removed_favorites'.tr()),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      cubit.addToFavourites(productId: productId, product: widget.product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product_added_favorites'.tr()),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // ─────────────────────── BUILD ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartCubit, CartState>(
      listener: (context, state) => _syncQuantityFromCart(),
      child: BlocBuilder<FavouritesCubit, FavouritesState>(
        buildWhen: (previous, current) {
          final pid = widget.product.effectiveId;
          if (pid <= 0) return false;

          final wasFav = previous is FavouritesSuccess && previous.isFavourite(pid);
          final isFav = current is FavouritesSuccess && current.isFavourite(pid);
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
            child: _buildPage(context, isFavorite),
          );
        },
      ),
    );
  }

  Widget _buildPage(BuildContext context, bool isFavorite) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product.product;
    final images = _getImages();
    final name = _getDisplayName();
    // Retail (oddiy) narx ekranda asosiy bo'lib turadi
    final retailPriceStr = _getDisplayPrice();
    final double retailPriceVal = double.tryParse(retailPriceStr) ?? 0;
    final bool hasRetailPrice = retailPriceVal > 0;
    // Hisob-kitoblar uchun (B2B foydalanuvchida B2B narx ishlatiladi)
    final effectivePriceStr = _getEffectivePrice();
    final oldPrice = _getOldPrice();
    final discountPercent = _getDiscountPercent();
    final hasDiscountPercent = discountPercent != null && discountPercent > 0;
    // Chegirma faqat eski va yangi narxlarning farqi bo'lsa hisobga olinadi.
    final hasDiscount =
        hasRetailPrice &&
        oldPrice != null &&
        oldPrice.trim().isNotEmpty &&
        (double.tryParse(oldPrice) ?? 0) > retailPriceVal;
    final b2bPriceStr = _getB2BPrice();
    final b2bPriceFormatted = b2bPriceStr != null
        ? NumberFormat.decimalPattern().format(double.tryParse(b2bPriceStr) ?? 0)
        : null;
    final showB2BLabel = _isB2BUser && b2bPriceFormatted != null && b2bPriceFormatted.trim().isNotEmpty;
    final measureStr = _getDisplayMeasureStr();
    final description = _getDisplayDescription();

    // Variantlar: agar 1 tadan ko'p bo'lsa, faqat variantlar ro'yxati ko'rsatiladi.
    final allVariants = widget.product.variants ?? [];
    // Faqat 1 tadan ko'p variant bo'lsa, variantlar blokini ko'rsatamiz
    final hasVariants = allVariants.length > 1;
    final selectedVariant = _getSelectedVariant();
    final selectedVariantName = selectedVariant?.names?.byLocale(_lang);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ──── APP BAR + IMAGE CAROUSEL ────
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            expandedHeight: 360,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(AppDimens.s8),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black26 : AppColors.bgTertiary,
                child: BackButton(color: isDark ? Colors.white : AppColors.primaryText),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(AppDimens.s8),
                child: CircleAvatar(
                  backgroundColor: isDark ? Colors.black26 : AppColors.bgTertiary,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      color: isFavorite ? AppColors.error : (isDark ? Colors.white : AppColors.primaryText),
                      size: AppDimens.icon24,
                    ),
                    onPressed: () => _toggleFavorite(isFavorite),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CarouselSlider.builder(
                          carouselController: _carouselSliderController,
                          itemCount: images.length,
                          itemBuilder: (context, index, realIndex) {
                            return CachedNetworkImage(
                              imageUrl: images[index].image ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: isDark ? Colors.grey.shade800 : AppColors.bgSecondary),
                              errorWidget: (context, url, error) => Icon(Icons.error, color: AppColors.secondaryText),
                            );
                          },
                          options: CarouselOptions(
                            height: double.infinity,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() => _currentImageIndex = index);
                            },
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: AppDimens.s16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: images.asMap().entries.map((entry) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _currentImageIndex == entry.key ? 24.0 : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppDimens.r4),
                                    color: _currentImageIndex == entry.key
                                        ? AppColors.primaryText.withValues(alpha: 0.9)
                                        : AppColors.primaryText.withValues(alpha: 0.3),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: isDark ? Colors.grey.shade800 : AppColors.bgSecondary,
                      child: Center(child: Icon(Icons.image, size: 50, color: AppColors.disabledText)),
                    ),
            ),
          ),

          // ──── PRODUCT INFO BODY ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.s20, vertical: AppDimens.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── B2B narx yorlig'i (faqat B2B user va mahsulotda B2B narx bo'lsa) ──
                  if (showB2BLabel && b2bPriceFormatted != null) ...[
                    _buildInfoChip(
                      icon: Icons.storefront_outlined,
                      label: '${'b2b_price_label'.tr()}: $b2bPriceFormatted ₩',
                      // Light mode: orange, Dark mode: gold
                      color: isDark ? AppColors.loyaltyCardGradientStart : AppColors.warning,
                    ),
                    const SizedBox(height: AppDimens.s8),
                  ],

                  // ── Price Row (asosiy, katta shrift) ──
                  if (hasRetailPrice) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${NumberFormat.decimalPattern().format(retailPriceVal)} ₩',
                          style: AppTextStyles.h1.copyWith(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (measureStr.isNotEmpty) ...[
                          const SizedBox(width: AppDimens.s6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/ $measureStr',
                              style: AppTextStyles.bodyM.copyWith(color: isDark?AppColors.secondaryTextDark: AppColors.secondaryText),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppDimens.s8),
                  ],

                  // ── Chegirma: eski narx + foiz badge ──
                  if (hasDiscount && hasRetailPrice) ...[
                    Row(
                      children: [
                        Text(
                          '${NumberFormat.decimalPattern().format(double.tryParse(oldPrice) ?? 0)} ₩',
                          style: AppTextStyles.bodyL.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.disabledText,
                          ),
                        ),
                        if (hasDiscountPercent) ...[
                          const SizedBox(width: AppDimens.s10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.s10,
                              vertical: AppDimens.s4,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimens.r8),
                            ),
                            child: Text(
                              '${'sale'.tr()} -$discountPercent%',
                              style: AppTextStyles.captionBold.copyWith(
                                color: CupertinoColors.activeGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppDimens.s8),
                  ],

                  // ── Product Name ──
                  Text(
                    name,
                    style: AppTextStyles.h2.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // ── Variantlar: faqat variantlar rasmlar ko‘rinishidagi gorizontal ro‘yxat ──
                  if (hasVariants) ...[
                    const SizedBox(height: AppDimens.s24),
                    _buildVariantSelector(allVariants),
                  ],

                  const SizedBox(height: AppDimens.s28),
                  Divider(color: isDark ? Colors.grey.shade800 : AppColors.border, height: 1),

                  // ── Description ──
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.s28),
                    Text(
                      'product_description'.tr(),
                      style: AppTextStyles.h3.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: AppDimens.s12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.s16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        border: Border.all(color: isDark ? Colors.grey.shade800 : AppColors.border, width: 1),
                      ),
                      child: _buildDescriptionRich(description),
                    ),
                  ],

                  const SizedBox(height: AppDimens.s100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  // ─────────────────── INFO CHIP ───────────────────

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s10, vertical: AppDimens.s6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimens.icon16, color: color),
          const SizedBox(width: AppDimens.s6),
          Text(label, style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─────────────────── DESCRIPTION RICH TEXT ───────────────────

  /// API dan kelgan tavsif matnini sarlavha va punktlar ko‘rinishida chiroyli qilib chiqaradi.
  /// - Oddiy satrlar: odatiy paragraf
  /// - "- " yoki "• " bilan boshlangan satrlar: bullet-item
  Widget _buildDescriptionRich(String description) {
    final lines = description.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rawLine in lines)
          _buildDescriptionLine(rawLine),
      ],
    );
  }

  Widget _buildDescriptionLine(String rawLine) {

    bool isDark=Theme.of(context).brightness==Brightness.dark;
    final line = rawLine.trimRight();
    if (line.isEmpty) {
      return const SizedBox(height: AppDimens.s8);
    }

    final trimmedLeft = line.trimLeft();
    final isBullet =
        trimmedLeft.startsWith('- ') || trimmedLeft.startsWith('• ');

    if (!isBullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.s4),
        child: Text(
          line,
          style: AppTextStyles.bodyL.copyWith(
            height: 1.6,
            color: isDark?AppColors.primaryTextDark: AppColors.primaryText,
          ),
        ),
      );
    }

    final text = trimmedLeft.substring(2).trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(width: AppDimens.s6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyL.copyWith(
                height: 1.6,
                color: isDark?AppColors.secondaryTextDark:AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── VARIANT SELECTOR ───────────────────

  /// Variantlar – faqat variantlar rasmlari ko'rsatiladigan gorizontal list.
  Widget _buildVariantSelector(List<ProductVariant> variants) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.s4),
        itemCount: variants.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.s10),
        itemBuilder: (context, index) {
          final variant = variants[index];
          final bool isSelected = variant.id != null && variant.id == _selectedVariantId;

          // Avval variant rasmini, bo'lmasa mahsulot rasmini olish
          String? imageUrl;
          if (variant.images != null && variant.images!.isNotEmpty) {
            imageUrl = variant.images!.first;
          } else if (widget.product.product?.images != null &&
              widget.product.product!.images!.isNotEmpty) {
            imageUrl = widget.product.product!.images!.first.image;
          }

          return GestureDetector(
            onTap: () => _selectVariant(variant.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.s14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.s10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.bgSecondary,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.bgSecondary,
                            child: Icon(
                              Icons.image_outlined,
                              size: 32,
                              color: AppColors.disabledText,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.bgSecondary,
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: AppColors.disabledText,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────── BOTTOM ACTION BAR ───────────────────

  Widget _buildBottomAction(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final cartItem = _findCartItem(cartState);
        final bool isInCart = cartItem != null;
        final int currentQty = isInCart ? (cartItem!.quantity ?? 1) : _quantity;

        // Faqat B2B foydalanuvchi va B2B narx mavjud bo'lsa minimal ulgurji miqdor logikasi ishlaydi
        final bool hasB2BPrice = _isB2BUser && _getB2BPrice() != null;
        final int minWholesaleQty = _getMinWholesaleQuantityForActive();

        // Narxni savatda bo'lsa cartItem.price dan,
        // bo'lmasa modeldan aniq raqam sifatida hisoblaymiz.
        final num unitPrice = isInCart
            ? (cartItem!.price ?? 0)
            : _getUnitPriceValue();

        // Agar backend line item uchun `total_price` yuborgan bo'lsa, aynan o'shani ko'rsatamiz,
        // aks holda unitPrice * currentQty dan foydalanamiz.
        final num totalForQty = isInCart && cartItem!.totalPrice != null
            ? (cartItem!.totalPrice!)
            : unitPrice * currentQty;

        final bool hasUnitPrice = unitPrice > 0;
        final bool hasTotalPrice = totalForQty > 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(AppDimens.s16, AppDimens.s12, AppDimens.s16, AppDimens.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : AppColors.primaryText.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Umumiy narx faqat haqiqiy narx bo'lganda ko'rsatiladi (0 bo'lsa ko'rsatmaymiz)
                    if (hasUnitPrice || hasTotalPrice) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (hasUnitPrice)
                        Text(
                          '$currentQty x ${NumberFormat.decimalPattern().format(unitPrice)} ₩',
                          style: AppTextStyles.bodyM.copyWith(color:isDark?AppColors.secondaryTextDark: AppColors.secondaryText),
                        )
                      else
                        Text(
                          '$currentQty',
                          style: AppTextStyles.bodyM.copyWith(color:isDark?AppColors.secondaryTextDark: AppColors.secondaryText),
                        ),
                      if (hasTotalPrice)
                        Text(
                          '${NumberFormat.decimalPattern().format(totalForQty)} ₩',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.s12),
                ],

                Row(
                  children: [
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                      ),
                      child: Row(
                        children: [
                          _buildQtyButton(
                            icon: Icons.remove,
                            onPressed: () {
                              if (isInCart) {
                                if (hasB2BPrice && minWholesaleQty > 1) {
                                  if (currentQty > minWholesaleQty) {
                                    context.read<CartCubit>().updateQuantity(
                                      cartItem.id!,
                                      currentQty - 1,
                                      orderId: cartItem.orderId,
                                    );
                                  } else {
                                    // minWholesaleQty ga teng bo'lsa, minus bosilganda butunlay o'chiramiz
                                    context.read<CartCubit>().removeFromCart(cartItem.id!);
                                  }
                                } else {
                                  if (currentQty > 1) {
                                    context.read<CartCubit>().updateQuantity(
                                      cartItem.id!,
                                      currentQty - 1,
                                      orderId: cartItem.orderId,
                                    );
                                  } else {
                                    context.read<CartCubit>().removeFromCart(cartItem.id!);
                                  }
                                }
                              } else {
                                if (hasB2BPrice && minWholesaleQty > 1) {
                                  if (_quantity > minWholesaleQty) {
                                    setState(() => _quantity--);
                                  }
                                } else {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                }
                              }
                            },
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '$currentQty',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyL.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          _buildQtyButton(
                            icon: Icons.add,
                            onPressed: () {
                              if (isInCart) {
                                context.read<CartCubit>().updateQuantity(
                                  cartItem.id!,
                                  currentQty + 1,
                                  orderId: cartItem.orderId,
                                );
                              } else {
                                setState(() => _quantity++);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.s14),

                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isActionLoading
                              ? null
                              : () async {
                                      if (!isInCart) {
                                        setState(() => _isActionLoading = true);
                                        try {
                                          final selectedVariant = _getSelectedVariant();
                                          await context.read<CartCubit>().addToCart(
                                            widget.product,
                                            quantity: _quantity,
                                            variantId: selectedVariant?.id,
                                          );
                                        } finally {
                                          if (mounted) setState(() => _isActionLoading = false);
                                        }
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const CartPage()),
                                        ).then((_) {
                                          if (mounted) _syncQuantityFromCart();
                                        });
                                      }
                                    },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInCart
                                ? AppColors.successVariant
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark ? Colors.grey.shade700 : AppColors.bgSecondary,
                            disabledForegroundColor: AppColors.disabledText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r12)),
                          ),
                          child: _isActionLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isInCart
                                          ? Icons.shopping_cart_checkout
                                          : Icons.add_shopping_cart,
                                      size: AppDimens.icon20,
                                    ),
                                    const SizedBox(width: AppDimens.s8),
                                    Flexible(
                                      child: Text(
                                        isInCart
                                            ? 'goto_cart'.tr()
                                            : 'add_cart'.tr(),
                                        style: AppTextStyles.button.copyWith(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQtyButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        child: SizedBox(
          width: 44,
          height: 52,
          child: Icon(
            icon,
            size: AppDimens.icon20,
            color: onPressed != null ? Theme.of(context).textTheme.bodyMedium?.color : AppColors.disabledText,
          ),
        ),
      ),
    );
  }
}
