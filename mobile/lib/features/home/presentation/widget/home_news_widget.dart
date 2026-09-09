import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../../notifications/data/models/news_model.dart';
import '../../../notifications/presentation/cubit/news_cubit.dart';
import '../../../notifications/presentation/page/news_detail_page.dart';
import '../../../notifications/presentation/page/notifications_page.dart';

class HomeNewsWidget extends StatefulWidget {
  /// If true, renders a full-page vertical list.
  /// If false (default), renders a compact horizontal list as a header.
  final bool fullPage;

  const HomeNewsWidget({super.key, this.fullPage = false});

  @override
  State<HomeNewsWidget> createState() => _HomeNewsWidgetState();
}

class _HomeNewsWidgetState extends State<HomeNewsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<NewsCubit>().state;
      if (state is NewsInitial || (state is NewsLoaded && (state).news.isEmpty)) {
        context.read<NewsCubit>().loadNews();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Bildirishnoma bosilganda: tashqi URL bo'lsa ochamiz (banner link ochish
  /// bilan bir xil naqsh), aks holda tafsilot sahifasini ochamiz.
  Future<void> _openNews(BuildContext context, NewsModel news) async {
    final link = news.link?.trim();
    if (link != null && link.isNotEmpty && link.startsWith('http')) {
      final uri = Uri.parse(link);
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
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailPage(news: news)),
    );
  }

  String _formatDate(BuildContext context, String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) return 'time_now'.tr();
          return 'time_minutes_ago'.tr(namedArgs: {'count': difference.inMinutes.toString()});
        }
        return 'time_hours_ago'.tr(namedArgs: {'count': difference.inHours.toString()});
      } else if (difference.inDays == 1) {
        return 'time_yesterday'.tr();
      } else if (difference.inDays < 7) {
        return 'time_days_ago'.tr(namedArgs: {'count': difference.inDays.toString()});
      } else {
        final locale = context.locale.toString();
        return DateFormat('dd MMM, yyyy', locale).format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading) {
          return widget.fullPage ? _buildFullPageShimmer() : _buildHorizontalShimmer(context);
        } else if (state is NewsError) {
          if (widget.fullPage) {
            return CommonErrorWidget(
              message: state.message,
              onRetry: () => context.read<NewsCubit>().loadNews(),
            );
          }
          return const SizedBox.shrink();
        } else if (state is NewsLoaded) {
          if (state.news.isEmpty) return const SizedBox.shrink();
          return widget.fullPage
              ? _buildFullPageList(context, state)
              : _buildHorizontalList(context, state.news.take(5).toList());
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─────────────── FULL PAGE (vertical list) ───────────────
  Widget _buildFullPageList(BuildContext context, NewsLoaded state) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            context.read<NewsCubit>().loadMoreNews();
          }
        }
        return false;
      },
      child: ListView.builder(
        // No explicit controller — participates in NestedScrollView's scroll
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.s16),
        itemCount: state.news.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.news.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _buildFullNewsItem(context, state.news[index]);
        },
      ),
    );
  }

  Widget _buildFullNewsItem(BuildContext context, NewsModel news) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _openNews(context, news),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.image != null && news.image!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.r16)),
                child: CachedNetworkImage(
                  imageUrl: news.image!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ShimmerWidget(width: double.infinity, height: 180),
                  errorWidget: (_, __, ___) => Container(
                    height: 180,
                    color: isDark ? Colors.grey.shade800 : AppColors.lightBackground,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: isDark ? Colors.grey.shade600 : Colors.grey, size: 40),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.s8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          news.typeLabelKey.tr(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(context, news.created),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.s12),
                  Text(
                    news.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.s8),
                  Text(
                    news.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.s16),
                  Row(
                    children: [
                      Text(
                        'news_read_more'.tr(),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPageShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.s16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppDimens.s16),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(AppDimens.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget(
              width: double.infinity,
              height: 180,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.r16)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerWidget(width: 80, height: 20, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(height: AppDimens.s12),
                  ShimmerWidget(width: double.infinity, height: 24, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(height: 8),
                  ShimmerWidget(width: 200, height: 24, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(height: AppDimens.s12),
                  ShimmerWidget(width: double.infinity, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(height: 4),
                  ShimmerWidget(width: double.infinity, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── HORIZONTAL HEADER (compact list) ───────────────
  Widget _buildHorizontalList(BuildContext context, List<NewsModel> newsList) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16, vertical: AppDimens.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'news'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
                child: Text(
                  'see_all'.tr(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
            scrollDirection: Axis.horizontal,
            itemCount: newsList.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppDimens.s12),
            itemBuilder: (_, index) => _buildHorizontalCard(context, newsList[index], isDark),
          ),
        ),
        const SizedBox(height: AppDimens.s16),
      ],
    );
  }

  Widget _buildHorizontalCard(BuildContext context, NewsModel news, bool isDark) {
    return GestureDetector(
      onTap: () => _openNews(context, news),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimens.r12),
          border: Border.all(color: Colors.grey.withOpacity(isDark ? 0.2 : 0.1)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: double.infinity,
              child: (news.image != null && news.image!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: news.image!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ShimmerWidget(width: double.infinity, height: double.infinity),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? Colors.grey.shade800 : AppColors.lightBackground,
                        child: Icon(Icons.image_not_supported_outlined,
                            color: isDark ? Colors.grey.shade600 : Colors.grey, size: 24),
                      ),
                    )
                  : Container(
                      color: isDark ? Colors.grey.shade800 : AppColors.lightBackground,
                      child: Icon(Icons.image_not_supported_outlined,
                          color: isDark ? Colors.grey.shade600 : Colors.grey, size: 24),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.s10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      news.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      news.description,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(context, news.created),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildHorizontalShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16, vertical: AppDimens.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerWidget(width: 100, height: 20, borderRadius: BorderRadius.all(Radius.circular(4))),
              ShimmerWidget(width: 60, height: 16, borderRadius: BorderRadius.all(Radius.circular(4))),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: AppDimens.s12),
            itemBuilder: (_, __) => ShimmerWidget(
              width: 240,
              height: double.infinity,
              borderRadius: BorderRadius.circular(AppDimens.r12),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.s16),
      ],
    );
  }
}
