import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../gen/assets.gen.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error'.tr())));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('help_center'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        // padding: const EdgeInsets.all(AppDimens.s16),
        children: [
          const SizedBox(height: AppDimens.s16),
          _buildHelpSection(
            context,
            title: 'help_app_title'.tr(),
            items: [
              _HelpItem(
                question: 'help_delivery_conditions_title'.tr(),
                answer: 'help_delivery_free'.tr(),
              ),
              _HelpItem(
                question: 'help_delivery_price_title'.tr(),
                answer:
                    '${'help_delivery_price_standard'.tr()}\n${'help_delivery_price_islands'.tr()}',
              ),
              _HelpItem(
                question: 'help_delivery_time_title'.tr(),
                answer: [
                  'help_delivery_time_weekdays'.tr(),
                  'help_delivery_time_friday'.tr(),
                  'help_delivery_time_sunday'.tr(),
                ].join('\n'),
              ),
              _HelpItem(
                question: 'help_delivery_arrival_title'.tr(),
                answer: [
                  'help_delivery_arrival_korea'.tr(),
                  'help_delivery_arrival_islands'.tr(),
                  'help_delivery_holidays_note'.tr(),
                ].join('\n'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s16),
          _buildHelpSection(
            context,
            title: 'help_quality_title'.tr(),
            items: [
              _HelpItem(
                question: 'help_quality_title'.tr(),
                answer: [
                  'help_quality_main'.tr(),
                  'help_quality_delay_note'.tr(),
                ].join('\n\n'),
              ),
              _HelpItem(
                question: 'help_quality_perishables_title'.tr(),
                answer: 'help_quality_perishables_body'.tr(),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s16),
          _buildHelpSection(
            context,
            title: 'help_payments_title'.tr(),
            items: [
              _HelpItem(
                question: 'help_payments_title'.tr(),
                answer: 'help_payments_body'.tr(),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s16),
          _buildHelpSection(
            context,
            title: 'help_b2b_title'.tr(),
            items: [
              _HelpItem(
                question: 'help_b2b_title'.tr(),
                answer: 'help_b2b_body'.tr(),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s16),
          _buildHelpSection(
            context,
            title: 'help_about_title'.tr(),
            items: [
              _HelpItem(
                question: 'help_about_title'.tr(),
                answer: 'help_about_body'.tr(),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s16),
          _buildHelpSection(
            context,
            title: 'help_paynet_title'.tr(),
            items: [
              _HelpItem(
                question: 'help_paynet_title'.tr(),
                answer: [
                  'help_paynet_status'.tr(),
                  'help_paynet_future'.tr(),
                ].join('\n\n'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s16),
          _buildHelpSection(
            context,
            title: 'help_faq_title'.tr(),
            items: [
              _HelpItem(
                question: 'help_faq_phone_q'.tr(),
                answer: 'help_faq_phone_a'.tr(),
              ),
              _HelpItem(
                question: 'help_faq_support_q'.tr(),
                answer: 'help_faq_support_a'.tr(),
              ),
              _HelpItem(
                question: 'help_faq_advantages_title'.tr(),
                answer: 'help_faq_advantages_body'.tr(),
              ),
              _HelpItem(
                question: 'help_faq_seller_q'.tr(),
                answer: 'help_faq_seller_a'.tr(),
              ),
              _HelpItem(
                question: 'help_faq_min_order_q'.tr(),
                answer: 'help_faq_min_order_a'.tr(),
              ),
              _HelpItem(
                question: 'help_faq_issue_q'.tr(),
                answer: 'help_faq_issue_a'.tr(),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s16),
          _buildContactSection(context),
          const SizedBox(height: AppDimens.s16),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context, {
    required String title,
    required List<_HelpItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimens.s16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
        // borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: AppDimens.s16),
          ...items.map((item) => _buildHelpItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, _HelpItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.s12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgMainDark : AppColors.bgMain,
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          side: BorderSide.none,
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          side: BorderSide.none,
        ),
        title: Text(
          item.question,
          style: const TextStyle(
            fontSize: AppDimens.s16,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.s16),
            child: Text(
              item.answer,
              style: TextStyle(
                fontSize: AppDimens.s14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
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
            onTap: () => _launchUrl(context, 'mailto:millionhalalmart2023@gmail.com'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.instagram,
            title: 'Instagram'.tr(),
            subtitle: '@million_qassob',
            onTap: () => _launchUrl(context, 'https://www.instagram.com/million_qassob'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.tiktok,
            title: 'TikTok'.tr(),
            subtitle: '@millionqassob',
            onTap: () => _launchUrl(context, 'https://www.tiktok.com/@millionqassob'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.telegram,
            title: 'Telegram'.tr(),
            subtitle: '@million_qassob',
            onTap: () => _launchUrl(context, 'https://t.me/million_qassob'),
          ),
          const Divider(),
          _buildContactItem(
            context,
            icon: Assets.icons.whatsapp,
            title: 'Whats App'.tr(),
            subtitle: '+82 10 9434 6468',
            onTap: () => _launchUrl(context, 'https://wa.me/821094346468'),
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
          child: SvgPicture.asset(icon)),
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
          fontSize: AppDimens.s14,
          // color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;

  _HelpItem({required this.question, required this.answer});
}
