
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/news_model.dart';
import '../../domain/repository/news_repository.dart';

part 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository repository;
  int _currentPage = 1;

  NewsCubit(this.repository) : super(NewsInitial());

  Future<void> loadNews() async {
    _currentPage = 1;
    emit(NewsLoading());
    final result = await repository.getNewsList(page: _currentPage);
    result.fold(
      (failure) => emit(NewsError(failure.error)),
      (response) => emit(NewsLoaded(
        news: response.results,
        hasMore: response.next != null,
      )),
    );
  }

  Future<void> loadMoreNews() async {
    if (state is NewsLoaded) {
      final currentState = state as NewsLoaded;
      if (currentState.isLoadingMore || !currentState.hasMore) return;

      emit(currentState.copyWith(isLoadingMore: true));
      
      _currentPage++;
      final result = await repository.getNewsList(page: _currentPage);
      
      result.fold(
        (failure) {
          // Keep existing data but stop loading
          emit(currentState.copyWith(isLoadingMore: false));
          // Optionally show error via separate side effect or temporary error state
        },
        (response) {
          emit(NewsLoaded(
            news: currentState.news + response.results,
            hasMore: response.next != null,
            isLoadingMore: false,
          ));
        },
      );
    }
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(NewsInitial());
}
