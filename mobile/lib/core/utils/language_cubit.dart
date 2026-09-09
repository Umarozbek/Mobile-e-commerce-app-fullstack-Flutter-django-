import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageCubit extends Cubit<String> {
  LanguageCubit() : super("uz");

  void changeLanguage(String language) {
    emit(language);
  }
  String get language => state;


}