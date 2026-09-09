import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../core/error/failure.dart';
import '../../../home/data/models/product_model.dart';
import '../../domain/repository/search_repository.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository _searchRepository;
  final _storage = GetStorage();
  final String _historyKey = 'search_history';

  SearchCubit(this._searchRepository) : super(SearchInitial()) {
    loadHistory();
  }

  SearchSuccess _getCurrentState() {
    if (state is SearchSuccess) {
      return state as SearchSuccess;
    }
    return SearchSuccess();
  }

  void loadHistory() {
    List<dynamic>? stored = _storage.read<List<dynamic>>(_historyKey);
    List<String> history = stored?.map((e) => e.toString()).toList() ?? [];
    
    // If not already success, emit success with history (and no data)
    // or if initial, just emit initial but we need a way to show history.
    // Let's emit SearchSuccess with empty data if state is Initial so UI can show history.
    if (state is SearchInitial) {
       emit(SearchSuccess(history: history));
    } else {
       final currentState = _getCurrentState();
       emit(currentState.copyWith(history: history));
    }
  }

  void addToHistory(String query) {
    if (query.trim().isEmpty) return;
    List<dynamic>? stored = _storage.read<List<dynamic>>(_historyKey);
    List<String> history = stored?.map((e) => e.toString()).toList() ?? [];

    history.removeWhere((element) => element.toLowerCase() == query.toLowerCase());
    history.insert(0, query);

    if (history.length > 10) {
      history = history.sublist(0, 10);
    }

    _storage.write(_historyKey, history);
    
    final currentState = _getCurrentState();
    emit(currentState.copyWith(history: history));
  }

  void removeFromHistory(String query) {
    List<dynamic>? stored = _storage.read<List<dynamic>>(_historyKey);
    List<String> history = stored?.map((e) => e.toString()).toList() ?? [];

    history.removeWhere((element) => element == query);
    _storage.write(_historyKey, history);

    final currentState = _getCurrentState();
    emit(currentState.copyWith(history: history));
  }

  void clearHistory() {
    _storage.remove(_historyKey);
    final currentState = _getCurrentState();
    emit(currentState.copyWith(history: []));
  }

  void searchProducts({required String query}) async {
    if (query.isEmpty) {
      // If empty, show history (SearchSuccess with null data and history)
      loadHistory();
      return;
    }

    addToHistory(query);

    final currentState = _getCurrentState();
    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['search'] = true,
      errorStates: Map.from(currentState.errorStates)..['search'] = null,
      nextUrls: Map.from(currentState.nextUrls)..['search'] = null,
      hasMore: Map.from(currentState.hasMore)..['search'] = false,
      clearData: true,
    ));

    final response = await _searchRepository.searchProducts(query: query);

    final updatedState = state is SearchSuccess ? state as SearchSuccess : _getCurrentState();
    response.fold(
      (l) => emit(updatedState.copyWith(
        loadingStates: Map.from(updatedState.loadingStates)..['search'] = false,
        errorStates: Map.from(updatedState.errorStates)..['search'] = l,
      )),
      (r) {
        if (r is ProductResponse) {
          final products = r.results ?? <ProductModel>[];

          emit(updatedState.copyWith(
            data: products,
            loadingStates: Map.from(updatedState.loadingStates)..['search'] = false,
            errorStates: Map.from(updatedState.errorStates)..['search'] = null,
            nextUrls: Map.from(updatedState.nextUrls)..['search'] = r.next,
            hasMore: Map.from(updatedState.hasMore)..['search'] = (r.next ?? '').isNotEmpty,
          ));
        } else if (r is List) {
          emit(updatedState.copyWith(
            data: r,
            loadingStates: Map.from(updatedState.loadingStates)..['search'] = false,
            errorStates: Map.from(updatedState.errorStates)..['search'] = null,
            hasMore: Map.from(updatedState.hasMore)..['search'] = false,
          ));
        } else {
          emit(updatedState.copyWith(
            data: r,
            loadingStates: Map.from(updatedState.loadingStates)..['search'] = false,
            errorStates: Map.from(updatedState.errorStates)..['search'] = null,
            hasMore: Map.from(updatedState.hasMore)..['search'] = false,
          ));
        }
      },
    );
  }

  void loadMoreSearchResults() async {
    final currentState = _getCurrentState();
    if (currentState.nextUrls['search'] == null || currentState.loadingStates['searchMore'] == true) {
      return;
    }

    emit(currentState.copyWith(
      loadingStates: Map.from(currentState.loadingStates)..['searchMore'] = true,
      errorStates: Map.from(currentState.errorStates)..['searchMore'] = null,
    ));

    final response = await _searchRepository.searchProductsNext(nextUrl: currentState.nextUrls['search']!);

    final updatedState = state is SearchSuccess ? state as SearchSuccess : _getCurrentState();
    response.fold(
      (l) {
        // Error bo'lganda mavjud datalarni saqlab qolish
        emit(updatedState.copyWith(
          loadingStates: Map.from(updatedState.loadingStates)..['searchMore'] = false,
          errorStates: Map.from(updatedState.errorStates)..['searchMore'] = l,
          // Mavjud datalar o'zgarmaydi, faqat error state yangilanadi
        ));
      },
      (r) {
        if (r is ProductResponse) {
          final currentProducts = (updatedState.data as List?) ?? [];
          final newProducts = r.results ?? <ProductModel>[];

          emit(updatedState.copyWith(
            data: [...currentProducts, ...newProducts],
            loadingStates: Map.from(updatedState.loadingStates)..['searchMore'] = false,
            errorStates: Map.from(updatedState.errorStates)..['searchMore'] = null,
            nextUrls: Map.from(updatedState.nextUrls)..['search'] = r.next,
            hasMore: Map.from(updatedState.hasMore)..['search'] = (r.next ?? '').isNotEmpty,
          ));
        } else {
          final currentProducts = (updatedState.data as List?) ?? [];
          emit(updatedState.copyWith(
            data: [...currentProducts, ...(r is List ? r : [r])],
            loadingStates: Map.from(updatedState.loadingStates)..['searchMore'] = false,
            errorStates: Map.from(updatedState.errorStates)..['searchMore'] = null,
            hasMore: Map.from(updatedState.hasMore)..['search'] = false,
          ));
        }
      },
    );
  }

  void clearSearch() {
    loadHistory(); // Instead of SearchInitial, go back to history view
  }

  /// Logout paytida state tozalanadi (qidiruv natijalari tozalanadi, history GetStorage dan o'chirilgan)
  void reset() => emit(SearchInitial());
}
