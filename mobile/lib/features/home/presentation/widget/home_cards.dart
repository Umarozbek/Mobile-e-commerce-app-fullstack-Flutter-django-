import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mart/core/utils/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../data/models/banner_model.dart';

/// Homecard: faqat API dan keladigan bannerlar (title, image). Hardcode yo'q.
class HomeCards extends StatefulWidget {
  final BannerModel model;
  const HomeCards({super.key, required this.model});

  @override
  State<HomeCards> createState() => _HomeCardsState();
}

class _HomeCardsState extends State<HomeCards> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final banners = widget.model.results ?? [];
    final activeBanners = banners
        .where((b) => b.active == true)
        .toList()
      ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

    if (activeBanners.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMultiple = activeBanners.length > 1;

    return Column(
      children: [
        const SizedBox(height: AppDimens.s20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimens.s10),
          height: dWith(context)* 8 / 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.r12),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.15),
            //     blurRadius: 12,
            //     offset: const Offset(0, 4),
            //   ),
            // ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.r12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Theme.of(context).cardColor,
                ),
                CarouselSlider.builder(
                  itemCount: activeBanners.length,
                  itemBuilder: (context, index, realIndex) {
                    final banner = activeBanners[index];
                    return _SlideContent(
                      title: banner.title,
                      imageUrl: banner.imageUrl ?? banner.image,
                      clickUrl: banner.clickUrl,
                    );
                  },
                  options: CarouselOptions(
                    viewportFraction: 1.0,
                    height:    dWith(context)* 8 / 16,
                    autoPlay: hasMultiple,
                    autoPlayInterval: const Duration(seconds: 7),
                    autoPlayAnimationDuration: const Duration(milliseconds: 500),
                    autoPlayCurve: Curves.easeInOut,
                    enlargeCenterPage: false,
                    onPageChanged: (index, reason) {
                      setState(() => _currentIndex = index);
                    },
                    enableInfiniteScroll: hasMultiple,
                  ),
                ),
                if (hasMultiple)
                  Positioned(
                    left: 0,
                    right: 0,
                    // left: 16,
                    bottom: 14,
                    child: Center(
                      child: Row(mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          activeBanners.length,
                          (index) => _IndicatorDot(
                            isActive: index == _currentIndex,
                            activeColor: AppColors.primary,
                            inactiveColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Slayd mazmuni: API dan title, image; link bo'lsa bosganda ochiladi.
class _SlideContent extends StatelessWidget {
  final String? title;
  final String? imageUrl;
  final String? clickUrl;

  const _SlideContent({
    this.title,
    this.imageUrl,
    this.clickUrl,
  });

  Future<void> _openLink(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
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
    final url = imageUrl?.trim() ?? '';
    final content = SizedBox(
      width: double.infinity,
      child: ClipRRect(
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: 160,
                height: 200,
                placeholder: (_, __) => const ShimmerWidget(
                  width: double.infinity,
                  height: double.infinity,
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : Icon(
                Icons.image_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
      ),
    );

    final link = clickUrl?.trim();
    if (link != null && link.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openLink(context, link),
        child: content,
      );
    }
    return content;
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const _IndicatorDot({
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Container(
        width: 30,
        height: 10,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(

          border: Border.all(color: Colors.white.withOpacity(0.5)),
          color: activeColor,
          borderRadius: BorderRadius.circular(13),
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: inactiveColor,
      ),
    );
  }
}
