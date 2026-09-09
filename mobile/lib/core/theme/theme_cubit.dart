import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final _box = GetStorage();
  final _key = 'theme_mode';

  ThemeCubit() : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    final savedTheme = _box.read(_key);
    if (savedTheme != null) {
      if (savedTheme == 'dark') {
        emit(ThemeMode.dark);
      } else if (savedTheme == 'light') {
        emit(ThemeMode.light);
      } else {
        emit(ThemeMode.system);
      }
    } else {
      emit(ThemeMode.dark); // Default
    }
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(newMode);
    _saveTheme(newMode);
  }

  void setTheme(ThemeMode themeMode) {
    emit(themeMode);
    _saveTheme(themeMode);
  }

  void _saveTheme(ThemeMode mode) {
    String value = 'dark';
    if (mode == ThemeMode.dark) value = 'dark';
    if (mode == ThemeMode.system) value = 'system';
    _box.write(_key, value);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}