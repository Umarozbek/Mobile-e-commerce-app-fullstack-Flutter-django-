import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../gen/assets.gen.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error'.tr())),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('help_contact_title'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppDimens.s16),
          _buildContactSection(context),
          const SizedBox(height: AppDimens.s16),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimens.s16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help_contact_title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: AppDimens.s16),
          Text(
            'help_contact_text_1'.tr(),
            style: TextStyle(
              fontSize: AppDimens.s14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimens.s8),
          Text(
            'help_contact_text_2'.tr(),
            style: TextStyle(
              fontSize: AppDimens.s14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimens.s8),
          Text(
            'help_contact_text_3'.tr(),
            style: TextStyle(
              fontSize: AppDimens.s14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimens.s12),
          Text(
            'help_contact_text_signature'.tr(),
            style: TextStyle(
              fontSize: AppDimens.s14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: AppDimens.s16),
          _buildContactItem(
            context,
            icon: Assets.icons.phone,
            title: 'help_contact_phone_title'.tr(),
            subtitle: '+82 10 9434 6468',
            onTap: () => _launchUrl(context, 'tel:+821094346468'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.email,
            title: 'help_contact_email_title'.tr(),
            subtitle: 'millionhalalmart2023@gmail.com',
            onTap: () =>
                _launchUrl(context, 'mailto:millionhalalmart2023@gmail.com'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.instagram,
            title: 'Instagram'.tr(),
            subtitle: '@million_qassob',
            onTap: () =>
                _launchUrl(context, 'https://www.instagram.com/million_qassob'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.tiktok,
            title: 'TikTok'.tr(),
            subtitle: '@millionqassob',
            onTap: () =>
                _launchUrl(context, 'https://www.tiktok.com/@millionqassob'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.telegram,
            title: 'Telegram'.tr(),
            subtitle: '@million_qassob',
            onTap: () =>
                _launchUrl(context, 'https://t.me/million_qassob'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.whatsapp,
            title: 'Whats App'.tr(),
            subtitle: '+82 10 9434 6468',
            onTap: () =>
                _launchUrl(context, 'https://wa.me/821094346468'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimens.s12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
        style: const TextStyle(
          fontSize: AppDimens.s14,
        ),
      ),
      onTap: onTap,
    );
  }
}

