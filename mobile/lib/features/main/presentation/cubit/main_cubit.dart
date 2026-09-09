import 'package:flutter_bloc/flutter_bloc.dart';

part 'main_state.dart';

class MainCubit extends Cubit<MainState> {
  MainCubit() : super(MainInitial());

  void changeTab(int index, {bool focusSearch = false}) {
    emit(MainTabChanged(index: index, focusSearch: focusSearch));
  }
}
