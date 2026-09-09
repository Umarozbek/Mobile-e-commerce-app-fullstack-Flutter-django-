part of 'main_cubit.dart';

abstract class MainState {}

class MainInitial extends MainState {}

class MainTabChanged extends MainState {
  final int index;
  final bool focusSearch;

  MainTabChanged({required this.index, this.focusSearch = false});
}
