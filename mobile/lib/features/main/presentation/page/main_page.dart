import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mart/core/constans/app_colors.dart';
import 'package:mart/core/constans/app_sizes.dart';
import 'package:mart/features/loyalty_card/presentation/page/loyalty_card_page.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/service/announcement_storage.dart';
import '../../../../core/service/secure_storage.dart';
import '../../../b2b/presentation/cubit/b2b_cubit.dart';
import '../../../notifications/data/models/announcement_data.dart';
import '../../../notifications/presentation/widget/announcement_dialog.dart';
import '../../../cart/presentation/page/cart_page.dart';
import '../../../home/presentation/page/home_page.dart';
import '../../../locations/presentation/cubit/location_cubit.dart';
import '../../../loyalty_card/presentation/cubit/loyalty_card_cubit.dart';
import '../../../profile/presentation/page/profile_page.dart';
import '../../../search/presentation/page/search_page.dart';
import '../cubit/main_cubit.dart';
import '../widget/main_bottom.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  /// Loyalty tab indeksi — LoyaltyCardPage da tab ko‘rinishini tekshirish uchun.
  static const int loyaltyTabIndex = 2;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const int _loyaltyTabIndex = MainPage.loyaltyTabIndex;

  late final MainCubit _mainCubit;
  late final ValueNotifier<bool> _showLoyaltyTutorTrigger;
  late final List<Widget> _pages;
  late Widget _loyaltyPage;

  @override
  void initState() {
    super.initState();
    _mainCubit = MainCubit();
    _showLoyaltyTutorTrigger = ValueNotifier(false);
    // Loyalty tab sahifasini faqat birinchi marta tab bosilganda
    // yaratamiz, shunda coachmark home ekranda avtomatik chiqib ketmaydi.
    _loyaltyPage = const SizedBox.shrink();
    _pages = [
      const HomePage(),
      const SearchPage(),
      _loyaltyPage,
      const CartPage(),
      const ProfilePage(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationCubit>().loadLocations();
      context.read<B2BCubit>().getB2BStatus();
      _showPendingAnnouncementIfAny();
    });
  }

  Future<void> _showPendingAnnouncementIfAny() async {
    var pending = await AnnouncementStorage.getPendingListRaw();
    while (pending.isNotEmpty &&
        AnnouncementStorage.isDismissed(
            AnnouncementData
                .fromJson(pending.first)
                .id)) {
      await AnnouncementStorage.removeFirstPending();
      pending = await AnnouncementStorage.getPendingListRaw();
    }
    if (pending.isEmpty) return;
    final first = AnnouncementData.fromJson(pending.first);
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) =>
            AnnouncementDialog(
              data: first,
              onClose: ({required bool doNotShowAgain}) {
                AnnouncementStorage.removeFirstPending();
                if (doNotShowAgain) {
                  AnnouncementStorage.addDismissedId(first.id);
                }
              },
            ),
      ),
    );
  }

  @override
  void dispose() {
    _mainCubit.close();
    _showLoyaltyTutorTrigger.dispose();
    super.dispose();
  }

  Future<void> _onLoyaltyTabSelected() async {
    // Agar hali LoyaltyCardPage yaratılmagan bo'lsa, endi yaratamiz
    if (_loyaltyPage is SizedBox) {
      setState(() {
        _loyaltyPage = const LoyaltyCardPage(enableAutoCoachOnFirstOpen: true);
        _pages[_loyaltyTabIndex] = _loyaltyPage;
      });
    }
    context.read<LoyaltyCardCubit>().loadLoyaltyData();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return BlocProvider<MainCubit>.value(
      value: _mainCubit,
      child: BlocBuilder<MainCubit, MainState>(
        builder: (context, state) {
          int currentIndex = 0;
          if (state is MainTabChanged) {
            currentIndex = state.index;
          }

          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: IndexedStack(
              index: currentIndex,
              children: _pages,
            ),
            bottomNavigationBar: MainBottom(
              index: currentIndex,
              onTabChanged: (index) {
                context.read<MainCubit>().changeTab(index);
                if (index == _loyaltyTabIndex) {
                  _onLoyaltyTabSelected();
                }
              },
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation
                .centerDocked,
            floatingActionButton: FloatingActionButton(
              backgroundColor:isDark?AppColors.bgSecondaryDark: Colors.white,
              disabledElevation: 0,
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,


              shape: CircleBorder(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: EdgeInsets.all(AppDimens.s4),
                padding: EdgeInsets.all(AppDimens.s10),
                decoration: BoxDecoration(
                   color: AppColors.primary,
                  boxShadow: [
                    if(currentIndex==2)
                    BoxShadow(
                      color: AppColors.primary.withAlpha(70),
                      blurRadius: 3,
                      spreadRadius: 5,
                      offset: Offset(0, 2)
                    )
                  ],
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(Assets.icons.creditCard,color: currentIndex==2?Colors.white:Colors.white54,),
              ),
              onPressed: () {
                context.read<MainCubit>().changeTab(2);

                _onLoyaltyTabSelected();
              },
            ),
          );
        },
      ),
    );
  }
}
