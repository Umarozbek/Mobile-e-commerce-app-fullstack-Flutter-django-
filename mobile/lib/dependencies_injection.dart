import 'package:get_it/get_it.dart';

import 'core/network/api_client.dart';
import 'core/service/firebase_messaging_service.dart';
import 'core/service/session_expired_service.dart';
import 'features/auth/data/repository/auth_repository_impl.dart';
import 'features/auth/domain/repository/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/b2b/data/datasource/b2b_remote_datasource.dart';
import 'features/b2b/data/repository/b2b_repository_impl.dart';
import 'features/b2b/domain/repository/b2b_repository.dart';
import 'features/b2b/presentation/cubit/b2b_cubit.dart';
import 'features/cart/data/repository/cart_repository_impl.dart';
import 'features/cart/domain/repository/cart_repository.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/favourites/data/repository/favourites_repository_impl.dart';
import 'features/favourites/domain/repository/favourites_repository.dart';
import 'features/favourites/presentation/cubit/favourites_cubit.dart';
import 'features/home/data/repository/home_repository_impl.dart';
import 'features/home/domain/repository/home_repository.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/locations/data/repository/location_repository_impl.dart';
import 'features/locations/domain/repository/location_repository.dart';
import 'features/locations/presentation/cubit/location_cubit.dart';
import 'features/loyalty_card/data/repository/loyalty_card_repository_impl.dart';
import 'features/loyalty_card/domain/repository/loyalty_card_repository.dart';
import 'features/loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import 'features/notifications/data/repository/news_repository_impl.dart';
import 'features/notifications/domain/repository/news_repository.dart';
import 'features/notifications/presentation/cubit/news_cubit.dart';
import 'features/orders/data/repository/order_repository_impl.dart';
import 'features/orders/domain/repository/order_repository.dart';
import 'features/orders/presentation/cubit/order_cubit.dart';
import 'features/product_detail/data/repository/product_detail_repository_impl.dart';
import 'features/product_detail/domain/repository/product_detail_repository.dart';
import 'features/product_detail/presentation/cubit/product_detail_cubit.dart';
import 'features/profile/data/repository/profile_repository_impl.dart';
import 'features/profile/domain/repository/profile_repository.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/referral/data/repository/referral_repository_impl.dart';
import 'features/referral/domain/repository/referral_repository.dart';
import 'features/referral/presentation/cubit/referral_cubit.dart';
import 'features/search/data/repository/search_repository_impl.dart';
import 'features/search/domain/repository/search_repository.dart';
import 'features/search/presentation/cubit/search_cubit.dart';

GetIt sl = GetIt.instance;

Future<void> serviceLocator({
  bool isUnitTest = false,
}) async {
  if (isUnitTest) {
    await sl.reset();
  }

  sl.registerSingleton<SessionExpiredService>(SessionExpiredService());
  sl.registerSingleton<ApiClient>(ApiClient(sl<SessionExpiredService>()));
  sl.registerSingleton<FirebaseMessagingService>(FirebaseMessagingService(sl<ApiClient>()));

  _dataSources();
  _repositories();
  _useCase();
  _blocs();
}

void _repositories() {
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<B2BRepository>(() => B2BRepositoryImpl(sl<B2BRemoteDataSource>()));
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<FavouritesRepository>(() => FavouritesRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<ProductDetailRepository>(() => ProductDetailRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<LoyaltyCardRepository>(() => LoyaltyCardRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<ReferralRepository>(() => ReferralRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<NewsRepository>(() => NewsRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(sl<ApiClient>()));
  sl.registerLazySingleton<LocationRepository>(() => LocationRepositoryImpl(sl<ApiClient>()));
}

void _dataSources() {
  sl.registerLazySingleton<B2BRemoteDataSource>(() => B2BRemoteDataSourceImpl(sl<ApiClient>()));
}

void _useCase() {}

void _blocs() {
  sl.registerFactory(() => AuthCubit(sl<AuthRepository>()));
  sl.registerFactory(() => B2BCubit(sl<B2BRepository>()));
  sl.registerLazySingleton(() => HomeCubit(sl<HomeRepository>()));
  sl.registerLazySingleton(() => FavouritesCubit(sl<FavouritesRepository>()));
  sl.registerFactory(() => SearchCubit(sl<SearchRepository>()));
  sl.registerFactory(() => ProductDetailCubit(sl<ProductDetailRepository>()));
  sl.registerFactory(() => ProfileCubit(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => LoyaltyCardCubit(sl<LoyaltyCardRepository>()));
  sl.registerLazySingleton(() => ReferralCubit(sl<ReferralRepository>()));
  sl.registerLazySingleton<CartCubit>(() => CartCubit(sl<CartRepository>()));
  sl.registerLazySingleton<LocationCubit>(() => LocationCubit(sl<LocationRepository>()));
  sl.registerLazySingleton<OrderCubit>(() => OrderCubit(sl<OrderRepository>()));
  sl.registerLazySingleton<NewsCubit>(() => NewsCubit(sl<NewsRepository>()));
}
