import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/b2b/presentation/cubit/b2b_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/favourites/presentation/cubit/favourites_cubit.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/locations/presentation/cubit/location_cubit.dart';
import '../../features/loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import '../../features/notifications/presentation/cubit/news_cubit.dart';
import '../../features/orders/presentation/cubit/order_cubit.dart';
import '../../features/product_detail/presentation/cubit/product_detail_cubit.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/referral/presentation/cubit/referral_cubit.dart';
import '../../features/search/presentation/cubit/search_cubit.dart';

/// Logout paytida barcha cubitlardagi session ma'lumotlarini tozalaydi.
/// [context] MultiBlocProvider ichida bo'lishi kerak.
void resetAllCubitsOnLogout(BuildContext context) {
  try {
    context.read<AuthCubit>().reset();
    context.read<B2BCubit>().reset();
    context.read<HomeCubit>().reset();
    context.read<FavouritesCubit>().reset();
    context.read<SearchCubit>().reset();
    context.read<ProductDetailCubit>().reset();
    context.read<ProfileCubit>().reset();
    context.read<LoyaltyCardCubit>().reset();
    context.read<ReferralCubit>().reset();
    context.read<CartCubit>().reset();
    context.read<LocationCubit>().reset();
    context.read<OrderCubit>().reset();
    context.read<NewsCubit>().reset();
  } catch (_) {
    // Context provider tree ichida bo'lmasa yoki cubit topilmasa e'tiborsiz qoldiramiz
  }
}
