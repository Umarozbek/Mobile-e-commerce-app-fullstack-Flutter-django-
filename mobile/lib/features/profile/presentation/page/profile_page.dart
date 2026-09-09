import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/service/firebase_messaging_service.dart';
import '../../../../core/service/logout_storage.dart';
import '../../../../core/utils/logout_cubits_reset.dart';
import '../../../../core/service/secure_storage.dart';
import '../../../../dependencies_injection.dart';
import '../../../../core/utils/b2b_helper.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../../auth/presentation/page/login_page.dart';
import '../../../b2b/presentation/cubit/b2b_cubit.dart';
import '../../../b2b/presentation/page/b2b_registration_page.dart';
import '../../../favourites/presentation/page/favourites_page.dart';
import '../../../help/presentation/page/help_page.dart';
import '../../../help/presentation/page/contact_page.dart';
import '../../../locations/presentation/page/locations_page.dart';
import '../../../loyalty_card/presentation/page/loyalty_card_page.dart';
import '../../../notifications/presentation/page/fcm_token_page.dart';
import '../../../orders/presentation/page/orders_page.dart';
import '../../../referral/presentation/page/referral_page.dart';
import '../../../settings/presentation/page/settings_page.dart';
import '../../data/models/profile_model.dart';
import '../../../b2b/data/models/b2b_status_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../gen/assets.gen.dart';
import '../cubit/profile_cubit.dart';
import '../widget/profile_shimmer.dart';
// import 'package:package_info_plus/package_info_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _fullName;
  String? _phoneNumber;
  bool _isB2BUser = false;
  B2BStatusModel? _b2bStatus;

  @override
  void initState() {
    super.initState();
    _loadStoredData();
    _checkB2BStatus();
    context.read<ProfileCubit>().getProfile();
  }

  Future<void> _checkB2BStatus() async {
    // We can still check local 'is_b2b_user' for immediate UI response if needed,
    // but we primarily want to fetch the status from API now.
    final isB2B = await B2BHelper.isB2BUser();
    if (mounted) {
      setState(() {
        _isB2BUser = isB2B;
      });
      // Also fetch detailed status from API
      context.read<B2BCubit>().getB2BStatus();
    }
  }

  Future<void> _loadStoredData() async {
    final fullName = await SecureStorage().read(key: 'full_name');
    final phoneNumber = await SecureStorage().read(key: 'phone_number');
    setState(() {
      _fullName = fullName;
      _phoneNumber = phoneNumber;
    });
  }

  Future<void> _onRefresh() async {
    context.read<ProfileCubit>().getProfile();
    context.read<B2BCubit>().getB2BStatus();
  }

  ProfileModel? _parseProfile(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      return ProfileModel.fromJson(data);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<B2BCubit, B2BState>(
      listener: (context, state) {
        if (state is B2BStatusChecked || state is B2BRegistrationSuccess) {
           _checkB2BStatus();
        }
        if (state is B2BStatusLoaded) {
          setState(() {
            _b2bStatus = state.status;
            _isB2BUser = state.status.isApprovedB2B;
          });
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgMainDark : AppColors.bgMain,
        appBar: AppBar(
          title: Text(
            'profile'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          surfaceTintColor: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
          // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 1,
          shadowColor: Colors.black12,
          scrolledUnderElevation: 1,
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading && state.type == 'profile') {
              return const ProfileShimmer();
            }

            if (state is ProfileError && state.type == 'profile') {
              return CommonErrorWidget(
                message: state.failure.error,
                onRetry: () => context.read<ProfileCubit>().getProfile(),
                icon: Icons.error_outline,
              );
            }

            if (state is ProfileSuccess && state.type == 'profile') {
              final profile = _parseProfile(state.data);
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppDimens.s16,),
                      // Profile Header
                      _buildProfileHeader(profile),
                      const SizedBox(height: AppDimens.s10),

                      // Hisob (Account) Section

                      _buildMenuContainer([
                        _buildSectionTitle('account_section'.tr()),
                        _buildMenuItem(
                          iconPath: Assets.icons.shoppingBag,
                          title: 'my_orders'.tr(), // Buyurtmalarim
                          subtitle: 'all_orders'.tr(), // Barcha buyurtmalar
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage())),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          iconPath: Assets.icons.heart,
                          title: 'my_favorites'.tr(), // Sevimlilarim
                          subtitle: 'saved_products'.tr(), // Saqlangan mahsulotlar
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouritesPage())),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          iconPath: Assets.icons.creditCard,
                          title: 'loyalty_card'.tr(), // Loyalty karta
                          subtitle: 'bonus_card'.tr(), // Bonus kartangiz
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyCardPage())),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          iconPath: Assets.icons.trophy,
                          title: 'referral_code'.tr(), // Referal kod
                          subtitle: 'share_code'.tr(), // Kodni ulashish va kiritish
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralPage())),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          iconPath: Assets.icons.phone,
                          title: 'help_contact_title'.tr(),
                          subtitle: 'help_contact_subtitle'.tr(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactPage(),
                            ),
                          ),
                        ),
                        // _buildDivider(),
                        // _buildMenuItem(
                        //   iconData: Icons.location_on_outlined,
                        //   title: 'my_addresses'.tr(), // Manzillarim
                        //   subtitle: 'delivery_addresses'.tr(), // Yetkazib berish manzillari
                        //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationsPage())),
                        // ),
                      ]),
                      const SizedBox(height: AppDimens.s10),

                      // Boshqaruv (Management) Section

                      _buildMenuContainer([
                        _buildSectionTitle('management_section'.tr()),
                        _buildMenuItem(
                          iconPath: Assets.icons.location,
                          title: 'my_addresses'.tr(),
                          subtitle: 'delivery_addresses'.tr(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LocationsPage(),
                            ),
                          ),
                        ),
                        // B2B: har qanday holatda item ko'rinadi,
                        // lekin matn statusga qarab o'zgaradi
                        _buildDivider(),
                        if (_b2bStatus != null && _b2bStatus!.isPending)
                          _buildMenuItem(
                            iconPath: Assets.icons.user,
                            title: 'b2b_application_pending'.tr(),
                            subtitle: 'b2b_pending_message'.tr(),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const B2BRegistrationPage(),
                              ),
                            ),
                          )
                        else if (_b2bStatus != null && _b2bStatus!.isApprovedB2B)
                          _buildMenuItem(
                            iconPath: Assets.icons.user,
                            title: 'b2b_status_approved_title'.tr(),
                            subtitle: 'b2b_status_approved_message'.tr(),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const B2BRegistrationPage(),
                              ),
                            ),
                          )
                        else if (_b2bStatus != null && _b2bStatus!.isRejected)
                          _buildMenuItem(
                            iconPath: Assets.icons.user,
                            title: 'b2b_status_rejected_title'.tr(),
                            subtitle: 'b2b_status_rejected_message'.tr(),
                            // REJECTED holatda yangi so'rov yuborish mumkin emas
                            onTap: () {},
                          )
                        else
                          _buildMenuItem(
                            iconPath: Assets.icons.user,
                            title: 'b2b_become_user'.tr(),
                            subtitle: 'b2b_benefits'.tr(),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const B2BRegistrationPage(),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(height: AppDimens.s10),

                      // Yordam (Help) Section

                      _buildMenuContainer([
                        _buildSectionTitle('help_section'.tr()),
                        _buildMenuItem(
                          iconPath: Assets.icons.settings,
                          title: 'settings'.tr(), // Sozlamalar
                          subtitle: 'app_settings'.tr(), // description...
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          ),
                        ),

                        _buildDivider(),
                        _buildMenuItem(
                          iconPath: Assets.icons.info,
                          title: 'help_center'.tr(),
                          subtitle: 'questions_answers'.tr(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HelpPage(),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppDimens.s10),

                      // Tizim (System) Section

                      _buildMenuContainer([
                        _buildSectionTitle('system_section'.tr()),
                        _buildMenuItem(
                          iconPath: Assets.icons.logout,
                          title: 'logout'.tr(), // Chiqish
                          subtitle: 'logout_subtitle'.tr(),
                          onTap: _showLogoutDialog,
                          isLast: true,
                        ),
                      ]),
                       const SizedBox(height: AppDimens.s40),
                    ],
                  ),
                ),
              );
            }

            return const ProfileShimmer();
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileModel? profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.s20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppDimens.r16),
      ),
      child: Column(
        children: [
          // Avatar
          SizedBox(
            width: 100,
            height: 100,
            child: profile?.image == null || profile!.image!.isEmpty
                ?  Image.asset("assets/images/user.png",
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              )
                : null,
          ),
          const SizedBox(height: AppDimens.s12),

          // Name
          Text(
            _fullName ?? profile?.fullName ?? 'Foydalanuvchi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),

          // Phone
          Text(
            _phoneNumber ?? profile?.phone ?? '',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.s16
          , left: AppDimens.s16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        // No shadow in screenshot, looks flat/clean or very subtle
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    String? iconPath,
    IconData? iconData,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.r16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16, vertical: AppDimens.s16),
        child: Row(
          children: [
            // Icon Background
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconPath != null
                  ? SvgPicture.asset(
                      iconPath,
                      // colorFilter: ColorFilter.mode(isDark ? Colors.grey.shade400 : Colors.grey.shade600, BlendMode.srcIn),
                    )
                  : Icon(iconData, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 22),
            ),
            const SizedBox(width: AppDimens.s16),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  // Remove old methods to avoid confusion/errors if not used
  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
       height: 1, 
       thickness: 0.5, 
       color: isDark ? Colors.grey.shade800 : const Color(0xFFF3F4F6), 
       indent: 72, // Align with text start
       endIndent: 0,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppDimens.s16),
          Text(
            'loading'.tr(), // TODO: Add 'loading' key
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: AppDimens.s14,
            ),
          ),
        ],
      ),
    );
  }



  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('attention'.tr()),
        content: Text('confirm_logout'.tr()),
        actions: [
          CupertinoDialogAction(
            child: Text('cancel'.tr()),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('logout'.tr()),
            onPressed: () async {
              Navigator.pop(context);
              // Backendda shu qurilmaning FCM tokenini faolsizlantiramiz —
              // JWT hali SecureStorage'da tozalanmasdan oldin (kerak bo'ladi).
              // Boshqa qurilmalarga (masalan planshetga) ta'sir qilmaydi.
              await sl<FirebaseMessagingService>().unregisterDeviceToken();
              // Cubitlardagi ma'lumotlarni tozalash
              resetAllCubitsOnLogout(context);
              // Til va onboarding saqlanadi, qolgan barcha ma'lumotlar tozalanadi
              await LogoutStorage.clearForLogout();

              // Navigate to login page
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // Future<void> _showAppInfoDialog() async {
  //   try {
  //     final packageInfo = await PackageInfo.fromPlatform();
  //     if (!context.mounted) return;
  //
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('about_app'.tr()),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('${'app_name'.tr()}: ${packageInfo.appName}'),
  //             const SizedBox(height: AppDimens.s8),
  //             Text('${'version'.tr()}: ${packageInfo.version}'),
  //             const SizedBox(height: AppDimens.s8),
  //             Text('${'build'.tr()}: ${packageInfo.buildNumber}'),
  //             const SizedBox(height: AppDimens.s16),
  //             const Text(
  //               'app_description'.tr(),
  //               style: TextStyle(
  //                 fontSize: AppDimens.s14,
  //                 color: Colors.grey,
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text('close'.tr()),
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     if (!context.mounted) return;
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('about_app'.tr()),
  //         content: Text('${'app_description'.tr()}\n${'app_description'.tr()}'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text('close'.tr()),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }
}
