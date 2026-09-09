
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mart/gen/assets.gen.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/service/firebase_messaging_service.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../dependencies_injection.dart';
import '../widget/language_selection_bottom_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final fcmService = sl<FirebaseMessagingService>();
    final isGranted = await fcmService.isPermissionGranted();
    setState(() {
      _notificationsEnabled = isGranted;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Request permission
      final fcmService = sl<FirebaseMessagingService>();
      final granted = await fcmService.requestNotificationPermission();

      setState(() {
        _notificationsEnabled = granted;
      });

      if (!granted) {
        // Show dialog to open settings
        if (mounted) {
          _showPermissionDialog();
        }
      }
    } else {
      // Open app settings to disable
      if (mounted) {
        _showDisableDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('permission_required'.tr()),
        content: Text('enable_notifications_text'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('settings'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDisableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('disable_notifications_title'.tr()),
        content: Text('disable_notifications_text'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('settings'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark?AppColors.bgMainDark:AppColors.bgMain,
      appBar: AppBar(
        title: Text('settings'.tr()),
        backgroundColor: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,

        surfaceTintColor:isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.s16),
        children: [

          Container(
            // padding: const EdgeInsets.all(AppDimens.s16),
            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(AppDimens.r12),
              color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('general'.tr()),
                _buildNotificationToggle(),
                _buildSettingItem(
                  icon: Assets.icons.globe,
                  title: 'language'.tr(),
                  subtitle: 'app_language'.tr(),
                  onTap: () => LanguageSelectionBottomSheet.show(context),
                ),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, state) {
                    String themeName = 'system_theme'.tr();
                    if (state == ThemeMode.light) themeName = 'light_theme'.tr();
                    if (state == ThemeMode.dark) themeName = 'dark_theme'.tr();

                    return _buildSettingItem(
                      icon: Assets.icons.sun,
                      title: 'theme'.tr(),
                      subtitle: themeName,
                      onTap: () {
                        _showThemeSelectionDialog();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.s16),
          // _buildSectionTitle('links'.tr()),
          // _buildSettingItem(
          //   icon: Assets.icons.share,
          //   title: 'share'.tr(),
          //   subtitle: 'share_app'.tr(),
          //   onTap: () {
          //     // TODO: Share app
          //   },
          // ),
          // _buildSettingItem(
          //   icon: Assets.icons.star,
          //   title: 'rate'.tr(),
          //   subtitle: 'rate_app'.tr(),
          //   onTap: () {
          //     // TODO: Rate app
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimens.s10),
        decoration: BoxDecoration(
          color: isDark?AppColors.bgSecondaryDark:AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppDimens.r12),
        ),
        child: SvgPicture.asset(Assets.icons.bell),
      ),
      title: Text(
        'notifications'.tr(),
        style: const TextStyle(
          fontSize: AppDimens.s16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _notificationsEnabled
            ? 'enabled'.tr()
            : 'disabled'.tr(),
        style: TextStyle(
          fontSize: AppDimens.s12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : CupertinoSwitch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              thumbColor: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
              activeColor: isDark?AppColors.primaryDark:AppColors.primary,
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimens.s16,
        top: AppDimens.s16,
        bottom: AppDimens.s8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppDimens.s14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimens.s10),
        decoration: BoxDecoration(
          color: isDark?AppColors.bgSecondaryDark:AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppDimens.r12),
        ),
        child: SvgPicture.asset(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimens.s16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: AppDimens.s12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  } void _showThemeSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.r20)),
      ),
      builder: (context) {
        final currentTheme = context.read<ThemeCubit>().state;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_theme'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimens.s16),
              _buildThemeOption(
                context,
                title: 'light_theme'.tr(),
                mode: ThemeMode.light,
                currentMode: currentTheme,
                icon: Assets.icons.sun,
              ),
              _buildThemeOption(
                context,
                title: 'dark_theme'.tr(),
                mode: ThemeMode.dark,
                currentMode: currentTheme,
                icon: Assets.icons.moon,
              ),
              _buildThemeOption(
                context,
                title: 'system_theme'.tr(),
                mode: ThemeMode.system,
                currentMode: currentTheme,
                icon: Assets.icons.processor,
              ),
              const SizedBox(height: AppDimens.s16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
      BuildContext context, {
        required String title,
        required ThemeMode mode,
        required ThemeMode currentMode,
        required String icon,
      }) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: SvgPicture.asset(icon,color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        context.read<ThemeCubit>().setTheme(mode);
        Navigator.pop(context);
        // Force rebuild to show updated selection next time if needed,
        // though BlocBuilder in main.dart handles the app theme change.
      },
    );
  }

}









