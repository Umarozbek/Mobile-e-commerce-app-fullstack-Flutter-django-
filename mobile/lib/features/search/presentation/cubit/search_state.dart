part of 'search_cubit.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {
  final String? type;
  SearchLoading({this.type});

  @override
  List<Object> get props => [type ?? ''];
}

final class SearchSuccess extends SearchState {
  final dynamic data;
  final Map<String, bool> loadingStates;
  final Map<String, Failure?> errorStates;
  final Map<String, String?> nextUrls; // For pagination
  final Map<String, bool> hasMore; // For pagination
  final List<String> history;

  SearchSuccess({
    this.data,
    Map<String, bool>? loadingStates,
    Map<String, Failure?>? errorStates,
    Map<String, String?>? nextUrls,
    Map<String, bool>? hasMore,
    List<String>? history,
  }) : loadingStates = loadingStates ?? {},
       errorStates = errorStates ?? {},
       nextUrls = nextUrls ?? {},
       hasMore = hasMore ?? {},
       history = history ?? [];

  SearchSuccess copyWith({
    dynamic data,
    Map<String, bool>? loadingStates,
    Map<String, Failure?>? errorStates,
    Map<String, String?>? nextUrls,
    Map<String, bool>? hasMore,
    List<String>? history,
    bool? clearData,
  }) {
    return SearchSuccess(
      data: clearData == true ? null : (data ?? this.data),
      loadingStates: loadingStates ?? Map.from(this.loadingStates),
      errorStates: errorStates ?? Map.from(this.errorStates),
      nextUrls: nextUrls ?? Map.from(this.nextUrls),
      hasMore: hasMore ?? Map.from(this.hasMore),
      history: history ?? List.from(this.history),
    );
  }

  @override
  List<Object> get props => [
    data ?? '',
    loadingStates,
    errorStates,
    nextUrls,
    hasMore,
    history,
  ];
}

final class SearchError extends SearchState {
  final Failure failure;
  final String? type;

  SearchError({required this.failure, this.type});

  @override
  List<Object> get props => [failure, type ?? ''];
}
