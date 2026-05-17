import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/core/services/local_cache_service.dart';

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
  final LocalCacheService _cacheService;
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  AppStateNotifier(this._cacheService) : super(AppState()) {
    _loadState();
  }

  void _loadState() {
    final themeIndex = _cacheService.get(LocalCacheService.settingsBoxName, _themeKey);
    final localeCode = _cacheService.get(LocalCacheService.settingsBoxName, _localeKey);

    state = state.copyWith(
      themeMode: themeIndex != null ? ThemeMode.values[themeIndex] : ThemeMode.dark,
      locale: localeCode != null ? Locale(localeCode) : const Locale('pt'),
    );
  }

  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: newMode);
    await _cacheService.put(LocalCacheService.settingsBoxName, _themeKey, newMode.index);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _cacheService.put(LocalCacheService.settingsBoxName, _themeKey, mode.index);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _cacheService.put(LocalCacheService.settingsBoxName, _localeKey, locale.languageCode);
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final cacheService = ref.watch(localCacheServiceProvider);
  return AppStateNotifier(cacheService);
});
