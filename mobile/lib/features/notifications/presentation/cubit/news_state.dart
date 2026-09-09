part of 'news_cubit.dart';

abstract class NewsState {}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<NewsModel> news;
  final bool hasMore;
  final bool isLoadingMore;

  NewsLoaded({
    required this.news,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  NewsLoaded copyWith({
    List<NewsModel>? news,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NewsLoaded(
      news: news ?? this.news,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NewsError extends NewsState {
  final String message;

  NewsError(this.message);
}
