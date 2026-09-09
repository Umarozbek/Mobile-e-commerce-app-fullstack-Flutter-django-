import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mart/core/constans/app_colors.dart';
import 'package:mart/core/constans/app_sizes.dart';
import 'package:mart/features/b2b/presentation/cubit/b2b_cubit.dart';
import 'package:mart/features/b2b/presentation/page/b2b_registration_page.dart';

/// Bosh sahifada qidiruvdan oldin ko'rinadigan kichik "Ulgurji savdogar bo'lish" karta.
/// Tasdiqlangan B2B foydalanuvchilarga ko'rsatilmaydi.
class B2BPromoCard extends StatelessWidget {
  const B2BPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B2BCubit, B2BState>(
      buildWhen: (prev, next) =>
          next is B2BStatusLoaded || next is B2BInitial || next is B2BLoading,
      builder: (context, state) {
        final bool isApproved = state is B2BStatusLoaded && state.status.isApprovedB2B;
        if (isApproved) return const SizedBox.shrink();

        final bool isPending = state is B2BStatusLoaded && state.status.isPending;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isPending
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const B2BRegistrationPage(),
                        ),
                      );
                    },
              borderRadius: BorderRadius.circular(AppDimens.r12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.s12,
                  vertical: AppDimens.s10,
                ),
                decoration: BoxDecoration(
                  gradient: isPending
                      ? null
                      : LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.12),
                            AppColors.primary.withOpacity(0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  border: Border.all(
                    color: isPending
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.border)
                        : AppColors.primary.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPending ? Icons.schedule_rounded : Icons.storefront_rounded,
                      size: 22,
                      color: isPending
                          ? Theme.of(context).hintColor
                          : AppColors.primary,
                    ),
                    const SizedBox(width: AppDimens.s10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPending
                                ? 'b2b_application_pending'.tr()
                                : 'b2b_become_user'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (!isPending) ...[
                            const SizedBox(height: 2),
                            Text(
                              'b2b_benefits'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isPending)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
