import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mart/core/utils/sizer.dart';
import 'package:mart/gen/assets.gen.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../../core/widgets/universal_button.dart';
import '../../data/models/referral_model.dart';
import '../cubit/referral_cubit.dart';
import '../widget/referral_shimmer.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReferralCubit>().getReferralCode();
  }

  ReferralModel? _getDisplayModel(ReferralState state) {
    if (state is ReferralSuccess && state.type == "getReferralCode" && state.data is ReferralModel) {
      return state.data as ReferralModel;
    }
    return null;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showCopySuccessDialog();
  }

  void _showCopySuccessDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (dialogContext) {
        // Dialog avtomatik yopilishi, lekin faqat dialog ochiq bo'lsa
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
        });
        return _CopySuccessDialog();
      },
    );
  }

  Future<void> _shareReferralCode(String code) async {
    const String appLink = 'https://taplink.cc/million_halal_market?from=qr';
    final String message = 'referral_share_message'.tr(namedArgs: {'code': code, 'link': appLink});
    try {
      await Share.share(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('referral_share_error'.tr()),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    context.read<ReferralCubit>().getReferralCode(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark=Theme.of(context).brightness==Brightness.dark;
    return Scaffold(
      backgroundColor: isDark?AppColors.bgMainDark:AppColors.bgMain,
      appBar: AppBar(
        title: Text('referral_system'.tr()),
        backgroundColor: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        surfaceTintColor:isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<ReferralCubit, ReferralState>(
        listener: (context, state) {
          if (state is ReferralError && state.type == "getReferralCode") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.failure.error.toString().replaceAll(RegExp(r'[{}"]'), ''),
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final displayModel = _getDisplayModel(state);
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.s16),
              physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll for refresh
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (displayModel != null) ...[
                     _buildBalanceCard(displayModel),
                     const SizedBox(height: AppDimens.s24),
                     _buildMyReferralCodeSection(displayModel),
                   ] else if (state is ReferralLoading && state.type == "getReferralCode") ...[
                      const ReferralShimmer(),
                   ] else if (state is ReferralError && state.type == "getReferralCode") ...[
                      CommonErrorWidget(
                        message: state.failure.error,
                        onRetry: _onRefresh,
                      ),
                   ],
                  if (displayModel != null && displayModel.myReferralsList.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.s24),
                    Text(
                      'referral_my_invites'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: AppDimens.s12),
                    ...displayModel.myReferralsList.map((e) => _buildReferralItem(e)),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(ReferralModel model) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.s20),
      decoration: BoxDecoration(
       gradient:    AppColors.loyaltyCardGradient,
        borderRadius: BorderRadius.circular(AppDimens.s16),

      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.s14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimens.r12),
            ),
            child: SvgPicture.asset(Assets.icons.wallet),
          ),
          const SizedBox(width: AppDimens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'balance'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${NumberFormat('#,###').format(model.balance ?? 0)} ₩",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReferralCodeSection(ReferralModel model) {
    final code = model.referralCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimens.s24),
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        // boxShadow: [
        //   if (!isDark)
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.04),
        //       blurRadius: 12,
        //       offset: const Offset(0, 4),
        //     ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Container(
              //   padding: const EdgeInsets.all(AppDimens.s10),
              //   decoration: BoxDecoration(
              //     color: AppColors.primary.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(AppDimens.r12),
              //   ),
              //   child: const Icon(Icons.share, color: AppColors.primary, size: 24),
              // ),
              // const SizedBox(width: AppDimens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'referral_your_code_title'.tr(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'referral_invite_friends'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.s24),
          // Referral kod - asosiy qism
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppDimens.s20, horizontal: AppDimens.s20),
            decoration: BoxDecoration(
              color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
              // gradient: LinearGradient(
              //   colors: [
              //     AppColors.primary.withOpacity(0.08),
              //     AppColors.primary.withOpacity(0.04),
              //   ],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
              borderRadius: BorderRadius.circular(AppDimens.r12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  code,
                  style:  TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: isDark ?AppColors.primaryTextDark:AppColors.primaryText,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: AppDimens.s20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Assets.icons.copy,
                        label: 'referral_copy'.tr(),
                        onTap: () => _copyToClipboard(code),
                      ),
                    ),
                    const SizedBox(width: AppDimens.s12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Assets.icons.share,
                        label: 'referral_share'.tr(),
                        onTap: () => _shareReferralCode(code),
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

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.s12),
          decoration: BoxDecoration(
            color: isDark ?AppColors.bgMainDark.withOpacity(0.1):AppColors.bgMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimens.r12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(icon),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralItem(ReferralItemModel item) {
    Color statusColor = Colors.grey;
    String statusText = item.status;
    
    if (item.status == 'rewarded') {
      statusColor = AppColors.success;
      statusText = 'referral_status_rewarded'.tr();
    } else if (item.status == 'pending') {
      statusColor = Colors.orange;
      statusText = 'referral_status_pending'.tr();
    }

    String formattedDate = item.createdAt;
    try {
      final date = DateTime.tryParse(item.createdAt);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
      }
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.s12),
      padding: const EdgeInsets.all(AppDimens.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.s10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.friendName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal dialog: yashil belgi va "Nusxa olindi!" matni.
class _CopySuccessDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8,minWidth: dWith(context)*0.7),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'nusxa_olindi'.tr(),
                style:  TextStyle(
                  color: isDark?AppColors.primaryTextDark:AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

