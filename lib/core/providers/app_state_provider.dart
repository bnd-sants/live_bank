import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  final ThemeMode themeMode;
  final Locale locale;

  AppState({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('pt'),
  });

  AppState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
