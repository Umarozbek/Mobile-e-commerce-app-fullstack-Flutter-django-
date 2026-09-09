import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';
import 'package:mart/core/constans/app_sizes.dart';

import 'package:mart/features/auth/presentation/page/login_page.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final GetStorage _storage = GetStorage();

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "onboarding_1_title",
      "image": Assets.images.board3.path,
    },
    {
      "title": "onboarding_2_title",
      "image": Assets.images.board1.path,    },
    {
      "title": "onboarding_3_title",
      "image": Assets.images.board2.path,    },
  ];

  List<TextSpan> _buildColoredTitleSpans(String text) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'\d+');
    int start = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final String numberText = match.group(0) ?? '';

      spans.add(
        TextSpan(
          text: numberText,
          style: const TextStyle(
            color: AppColors.successVariant,
            fontSize: AppDimens.s24,
            fontWeight: FontWeight.w700
          ),
        ),
      );

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _completeOnboarding() {
    _storage.write('is_first_time', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 8,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        // borderRadius: BorderRadius.circular(AppDimens.s10)
                      ),

                        child: Image.asset(_onboardingData[_currentPage]["image"],fit: BoxFit.cover,));
                  },
                ),
              ),
              Expanded(
                flex: 4,
                child: SizedBox(),
              ),
            ],
          ),
          Column(
            children: [
              Expanded(
                flex: 6,
                child: SizedBox(),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.bgMainDark,
                    // gradient: AppColors.primaryGradient, // Use Gradient
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Builder(builder: (context) {
                            final String title =
                                _onboardingData[_currentPage]["title"]!
                                    .toString()
                                    .tr();

                            return Text.rich(
                              TextSpan(
                                children: _buildColoredTitleSpans(title),
                              ),
                              key: ValueKey<int>(_currentPage),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppDimens.s20,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            );
                          }),
                        ),
                      ),

                      // Bottom Navigation Row
                      if (_currentPage == _onboardingData.length - 1)
                        Column(
                          children: [
                            // Dots Indicator (Centered)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _onboardingData.length,
                                    (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentPage == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentPage == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Login Button (Full Width)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _completeOnboarding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  "onboarding_login".tr(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Dots Indicator
                            Row(
                              children: List.generate(
                                _onboardingData.length,
                                    (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 8),
                                  width: _currentPage == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentPage == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),

                            // Next Button (Circular)
                            GestureDetector(
                              onTap: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Skip Button (Positioned at Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: _currentPage != _onboardingData.length - 1
                ? TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                    ),
                    child: Text(
                      "onboarding_skip".tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
