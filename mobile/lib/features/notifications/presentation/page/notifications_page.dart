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
import '../../data/models/news_model.dart';
import '../cubit/news_cubit.dart';
import 'news_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsCubit>().loadNews();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NewsCubit>().loadMoreNews();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<NewsCubit>().loadNews();
  }

  /// Bildirishnoma bosilganda: agar `link` tashqi URL bo'lsa uni ochamiz
  /// (home_cards.dart dagi banner link ochish bilan bir xil naqsh),
  /// aks holda (link yo'q yoki ichki route) tafsilot sahifasini ochamiz.
  Future<void> _openNews(NewsModel news) async {
    final link = news.link?.trim();
    if (link != null && link.isNotEmpty && link.startsWith('http')) {
      final uri = Uri.parse(link);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error'.tr())),
          );
        }
      }
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailPage(news: news)),
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
          if (difference.inMinutes == 0) {
            return 'time_now'.tr();
          }
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('news'.tr()),
        elevation: 1,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading) {
            return _buildLoadingState();
          } else if (state is NewsError) {
            return CommonErrorWidget(
              message: state.message,
              onRetry: () => context.read<NewsCubit>().loadNews(),
              title: 'news_error_title'.tr(),
            );
          } else if (state is NewsLoaded) {
            if (state.news.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppDimens.s16),
                itemCount: state.news.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.news.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return _buildNewsItem(state.news[index]);
                },
              ),
            );
          }
           else if (state is NewsInitial) {
             return _buildLoadingState();
           }
          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildNewsItem(NewsModel news) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.r16),
          onTap: () => _openNews(news),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              if (news.image != null && news.image!.isNotEmpty)
                Hero(
                  tag: 'news_image_${news.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimens.r16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: news.image!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerWidget(
                        width: double.infinity,
                        height: 180,
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: isDark ? Colors.grey.shade800 : AppColors.lightBackground,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: isDark ? Colors.grey.shade600 : Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(AppDimens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge & Date Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.s8,
                            vertical: 4,
                          ),
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
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(context, news.created),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.s12),
                    
                    // Title
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
                    
                    // Description
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
                    
                    // Read More Link
                    Row(
                      children: [
                        Text(
                          'news_read_more'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.s16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimens.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimens.r16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerWidget(
                width: double.infinity,
                height: 180,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimens.r16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerWidget(
                      width: 80,
                      height: 20,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: AppDimens.s12),
                    const ShimmerWidget(
                      width: double.infinity,
                      height: 24,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: 8),
                    const ShimmerWidget(
                      width: 200,
                      height: 24,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: AppDimens.s12),
                    const ShimmerWidget(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: 4),
                    const ShimmerWidget(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: AppDimens.s24),
          Text(
            'news_empty_title'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: AppDimens.s12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'news_empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
