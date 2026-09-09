import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../loyalty_card/data/models/loyalty_card_model.dart';
import '../../../loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import '../../../loyalty_card/presentation/page/loyalty_card_page.dart';

class LoyaltyCardWidget extends StatelessWidget {
  const LoyaltyCardWidget({super.key});

  LoyaltyCardModel? _parseLoyaltyCard(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      try {
        return LoyaltyCardModel.fromJson(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyCardCubit, LoyaltyCardState>(
      builder: (context, state) {
        if (state is LoyaltyCardSuccess) {
          final loyaltyCard = _parseLoyaltyCard(state.data);
          if (loyaltyCard != null) {
            return _buildCard(context, loyaltyCard);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCard(BuildContext context, LoyaltyCardModel card) {
    final balance = card.balance ?? 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoyaltyCardPage(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
        padding: const EdgeInsets.all(AppDimens.s16),
        decoration: BoxDecoration(
          gradient: AppColors.loyaltyCardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.loyaltyCardGradientEnd.withValues(alpha: 0.35),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MILLION VIP CARD',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppDimens.s4),
                  Text(
                    '${balance.toStringAsFixed(0)} ₩',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.98),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.9),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}








