

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mart/features/main/presentation/cubit/main_cubit.dart';
import 'package:mart/features/main/presentation/page/main_page.dart';
import 'package:mart/gen/assets.gen.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../../../core/service/secure_storage.dart';
import '../../data/models/loyalty_card_model.dart';
import '../../data/models/loyalty_history_model.dart';
import '../cubit/loyalty_card_cubit.dart';
import '../widget/loyalty_card_shimmer.dart';

class LoyaltyCardPage extends StatefulWidget {
  /// Faqat main bottomdagi LoyaltyCard tabidan kirilganda birinchi marta
  /// auto-coachmark ishlashi uchun flag.
  final bool enableAutoCoachOnFirstOpen;

  const LoyaltyCardPage({
    super.key,
    this.enableAutoCoachOnFirstOpen = false,
  });

  @override
  State<LoyaltyCardPage> createState() => _LoyaltyCardPageState();
}

class _LoyaltyCardPageState extends State<LoyaltyCardPage> {
  /// Coach marks
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _cycleKey = GlobalKey();
  final GlobalKey _infoKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  List<TargetFocus> _targets = [];
  TutorialCoachMark? _tutorialCoachMark;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _currentTutorialTargetIndex = ValueNotifier(0);
  bool _autoCoachTried = false;

  @override
  void initState() {
    super.initState();
    context.read<LoyaltyCardCubit>().loadLoyaltyData();
  }

   @override
  void dispose() {
    _tutorialCoachMark?.finish();
    _currentTutorialTargetIndex.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<LoyaltyCardCubit>().loadLoyaltyData(forceRefresh: true);
  }

  Future<void> _maybeShowCoachMarks({bool force = false}) async {
    // Yangi versiya uchun alohida kalit – eski qiymat ta'sir qilmaydi
    final shown = await SecureStorage().read(key: 'loyalty_coach_shown_v2');
    if (!force && shown == 'true') return;

    _initTargets();

    _currentTutorialTargetIndex.value = 0;
    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black.withValues(alpha: 0.8),
      paddingFocus: 8,
      opacityShadow: 0.8,
      skipWidget: ValueListenableBuilder<int>(
        valueListenable: _currentTutorialTargetIndex,
        builder: (context, index, _) => TextButton(
          onPressed: () {
            if (index == 3) {
              SecureStorage().write(key: 'loyalty_coach_shown_v2', value: 'true');
              _tutorialCoachMark?.finish();
            } else {
              _tutorialCoachMark?.next();
            }
          },
          child: Text(
            index == 3 ? 'finish_tutorial'.tr() : 'next'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      // Har bir targetdan oldin kerakli joyga scroll qilamiz va tugma matnini yangilaymiz
      beforeFocus: (target) async {
        if (!mounted) return;
        if (target.identify == 'loyalty_card_main') {
          _currentTutorialTargetIndex.value = 0;
          await _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else if (target.identify == 'loyalty_cycle') {
          _currentTutorialTargetIndex.value = 1;
          final ctx = _cycleKey.currentContext;
          if (ctx != null) {
            await Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.3, // taxminan ekranning o‘rtasiga yaqin
            );
          }
        } else if (target.identify == 'loyalty_how_it_works') {
          _currentTutorialTargetIndex.value = 2;
          final ctx = _infoKey.currentContext;
          if (ctx != null) {
            await Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.3,
            );
          }
        } else if (target.identify == 'loyalty_history') {
          _currentTutorialTargetIndex.value = 3;
          final ctx = _historyKey.currentContext;
          if (ctx != null) {
            await Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              alignment: 0.3,
            );
          }
        }
      },
      onFinish: () {
        SecureStorage().write(key: 'loyalty_coach_shown_v2', value: 'true');
      },
      onSkip: () {
        _tutorialCoachMark?.next();
        return false;
      },
    );

    if (!mounted) return;
    _tutorialCoachMark?.show(context: context, rootOverlay: true);
  }

  void _initTargets() {
    _targets = [
      TargetFocus(
        identify: 'loyalty_card_main',
        keyTarget: _cardKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'loyalty_coach_card_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'loyalty_coach_card_body'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'loyalty_cycle',
        keyTarget: _cycleKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'loyalty_coach_cycle_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'loyalty_coach_cycle_body'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'loyalty_how_it_works',
        keyTarget: _infoKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'loyalty_coach_info_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'loyalty_coach_info_body'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'loyalty_history',
        keyTarget: _historyKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'loyalty_coach_history_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'loyalty_coach_history_body'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark?AppColors.bgMainDark:AppColors.bgMain,
      appBar: AppBar(
        title: Text('loyalty_card'.tr()),
        // backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _maybeShowCoachMarks(force: true);
            },
          ),
        ],
        backgroundColor: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        surfaceTintColor:isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        elevation: 1,
        shadowColor: isDark ? Colors.black26 : Colors.black12,
      ),
      body: BlocBuilder<LoyaltyCardCubit, LoyaltyCardState>(
        builder: (context, state) {
          if (state is LoyaltyCardLoading) {
            return _buildLoadingState();
          }
          if (state is LoyaltyCardError) {
            return CommonErrorWidget(
              message: state.failure.error,
              onRetry: () => context.read<LoyaltyCardCubit>().loadLoyaltyData(),
            );
          }
          if (state is LoyaltyCardSuccess) {
            final loyaltyCard = state.data;
            final history = state.history;

            // Ma'lumot yuklangandan keyin auto-coach faqat foydalanuvchi hali Loyalty tabda
            // turgan bo'lsa ishlashi kerak (boshqa tabga o'tib ketgan bo'lsa ishga tushmasin)
            if (widget.enableAutoCoachOnFirstOpen && !_autoCoachTried) {
              _autoCoachTried = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                // Layout va GlobalKey'lar tayyor bo'lishi uchun qisqa kechikish (birinchi marta coach chiqishi uchun)
                Future<void>.delayed(const Duration(milliseconds: 450), () {
                  if (!mounted) return;
                  final mainCubit = context.read<MainCubit>();
                  final state = mainCubit.state;
                  final isLoyaltyTabVisible = state is MainTabChanged &&
                      state.index == MainPage.loyaltyTabIndex;
                  if (isLoyaltyTabVisible) {
                    _maybeShowCoachMarks();
                  }
                });
              });
            }
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: AppDimens.s16),
                    _buildLoyaltyCard(loyaltyCard),
                    const SizedBox(height: AppDimens.s24),
                    _buildCycleInfoSection(loyaltyCard),
                    const SizedBox(height: AppDimens.s24),
                    _buildInfoSection(),
                    const SizedBox(height: AppDimens.s24),
                    _buildHistoryList(history),
                    const SizedBox(height: AppDimens.s16),
                  ],
                ),
              ),
            );
          }
          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildLoyaltyCard(LoyaltyCardModel? card) {

    final balance = card?.balance ?? 0.0;
    final fullName = card?.fullName ?? 'user_default_name'.tr();
    final cycleEnd = card?.cycleEnd;
    final expiryCard = cycleEnd != null && cycleEnd.isNotEmpty
        ? _formatExpiryCard(cycleEnd)
        : null;

    return Container(
      key: _cardKey,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
      padding: const EdgeInsets.all(AppDimens.s24),
      decoration: BoxDecoration(
        gradient: AppColors.loyaltyCardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.loyaltyCardGradientEnd.withValues(alpha: 0.4),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MILLION VIP CARD — yuqori chap
          Text(
            'MILLION VIP CARD',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimens.s16),
          // Balans — yirik, oq/kulrang
          Text(
            '${balance.toStringAsFixed(0)} ₩',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.98),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppDimens.s16),
          // Pastki qator: Karta egasi + ism | Muddati + 03/26
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'card_holder_label'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (expiryCard != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'muddati'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expiryCard,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format cycle end as "03 / 26" for card display.
  String? _formatExpiryCard(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) return null;
    final date = DateTime.tryParse(expiryDate);
    if (date == null) return null;
    return DateFormat('MM / yy').format(date);
  }

  int? _getDaysRemaining(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) return null;
    
    try {
      final expiry = DateTime.tryParse(expiryDate);
      if (expiry == null) return null;
      
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;
      
      return difference >= 0 ? difference : 0;
    } catch (e) {
      return null;
    }
  }

  String _formatExpiryDate(BuildContext context, String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) return 'not_exist'.tr();
    
    try {
      final date = DateTime.tryParse(expiryDate);
      if (date == null) return expiryDate;
      final locale = context.locale.toString();
      return DateFormat('dd MMMM, yyyy', locale).format(date);
    } catch (e) {
      return expiryDate;
    }
  }


  Widget _buildCycleInfoSection(LoyaltyCardModel? card) {
    final cycleStart = _formatExpiryDate(context, card?.cycleStart);
    final cycleEnd = _formatExpiryDate(context, card?.cycleEnd);
    final cycleNumber = card?.cycleNumber ?? 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: _cycleKey,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
      padding: const EdgeInsets.all(AppDimens.s20),
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        // boxShadow: [
        //   BoxShadow(
        //     color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withValues(alpha: 0.1),
        //     spreadRadius: 1,
        //     blurRadius: 4,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          // Text(
          //   'cycle'.tr(args: [cycleNumber.toString()]),
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.bold,
          //     color: Theme.of(context).textTheme.bodyLarge?.color,
          //   ),
          // ),
          // const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_month,
                  title: 'start'.tr(),
                  value: cycleStart,
                  color: Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.event_busy,
                  title: 'end'.tr(),
                  value: cycleEnd,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    bool isDark=Theme.of(context).brightness==Brightness.dark;
    return Column(
      children: [
        SvgPicture.asset(Assets.icons.calendarDates),
        const SizedBox(height: AppDimens.s8),
        Text(
          title,
          style: TextStyle(
            fontSize: AppDimens.s12,
            color: isDark?AppColors.secondaryTextDark:AppColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.s4),
        Text(
          value,
          style: TextStyle(
            fontSize: AppDimens.s14,
            fontWeight: FontWeight.w400,
            color: isDark?AppColors.primaryTextDark:AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: _infoKey,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
      padding: const EdgeInsets.all(AppDimens.s20),
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        // boxShadow: [
        //   BoxShadow(
        //     color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withValues(alpha: 0.1),
        //     spreadRadius: 1,
        //     blurRadius: 4,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'how_it_works'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppDimens.s16),
          _buildInfoItem(
            icon: Assets.icons.shoppingCart,
            text: 'loyalty_info_1'.tr(),
          ),
          const SizedBox(height: AppDimens.s12),
          _buildInfoItem(
            icon: Assets.icons.star,
            text: 'loyalty_info_2'.tr(),
          ),
          const SizedBox(height: AppDimens.s12),
          _buildInfoItem(
            icon: Assets.icons.trophy,
            text: 'loyalty_info_3'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.s8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(AppDimens.r8),
          ),
          child: SvgPicture.asset(icon),
        ),
        const SizedBox(width: AppDimens.s12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppDimens.s14,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const LoyaltyCardShimmer();
  }

  Widget _buildHistoryList(LoyaltyHistoryResponse? history) {
    if (history == null) return const SizedBox.shrink();

    final spending = history.spendingHistory;
    final cashback = history.cashbackHistory;
    final referral = history.referralHistory;

    // 1. Create a unified list of map items for display
    List<Map<String, dynamic>> allHistory = [];

    // Add Spending
    for (var item in spending) {
      allHistory.add({
        'type': 'spending',
        'title': "order_number".tr(args: [item.orderNumber ?? '']),
        'subtitle': item.createdAt,
        'amount': item.loyaltyPayment,
        'isNegative': true,
        'date': item.createdAt,
      });
    }

    // Add Cashback (API: order_number, order_amount, percent, bonus_amount, status, created_at, type)
    for (var item in cashback) {
      allHistory.add({
        'type': 'cashback',
        'title': "cashback_order".tr(args: [item.orderNumber]),
        'subtitle': item.createdAt,
        'amount': item.bonusAmount,
        'isNegative': false,
        'date': item.createdAt,
      });
    }

    // Add Referral
    for (var item in referral) {
      allHistory.add({
        'type': 'referral',
        'title': "referral_bonus".tr(args: [item.friendName ?? '']),
        'subtitle': item.createdAt,
        'amount': item.bonusAmount,
        'isNegative': false,
        'date': item.createdAt,
      });
    }

    // 2. Sort by date descending
    allHistory.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // 3. Limit max items to avoid building too many widgets (performance safeguard)
    const int maxItemsToShow = 100;
    if (allHistory.length > maxItemsToShow) {
      allHistory = allHistory.take(maxItemsToShow).toList();
    }

    if (allHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text("history_empty".tr())),
      );
    }

    const int tutorHistoryItemCount = 3;
    final firstItems = allHistory.take(tutorHistoryItemCount).toList();
    final restItems = allHistory.skip(tutorHistoryItemCount).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "history".tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 10),
          Container(
            key: _historyKey,
            child: Column(
              children: firstItems.map((item) {
                final amountStr = item['amount'].toStringAsFixed(0);
                final sign = item['isNegative'] ? "-" : "+";
                return _buildHistoryItem(
                  title: item['title'],
                  subtitle: _formatExpiryDate(context, item['date'].toIso8601String()),
                  amount: "$sign$amountStr ₩",
                  isNegative: item['isNegative'],
                );
              }).toList(),
            ),
          ),
          if (restItems.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: restItems.length,
              itemBuilder: (context, index) {
                final item = restItems[index];
                final amountStr = item['amount'].toStringAsFixed(0);
                final sign = item['isNegative'] ? "-" : "+";
                return _buildHistoryItem(
                  title: item['title'],
                  subtitle: _formatExpiryDate(context, item['date'].toIso8601String()),
                  amount: "$sign$amountStr ₩",
                  isNegative: item['isNegative'],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String subtitle,
    required String amount,
    required bool isNegative,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}




