import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalCacheService {
  static const String transactionsBoxName = 'transactions';
  static const String investmentsBoxName = 'investments';
  static const String cardsBoxName = 'cards';
  static const String settingsBoxName = 'settings';
  static const String userBoxName = 'user';

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Abrir os boxes necessários
    await Future.wait([
      Hive.openBox(transactionsBoxName),
      Hive.openBox(investmentsBoxName),
      Hive.openBox(cardsBoxName),
      Hive.openBox(settingsBoxName),
      Hive.openBox(userBoxName),
    ]);
  }

  // Métodos genéricos de persistência
  Future<void> put(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  dynamic get(String boxName, String key, {dynamic defaultValue}) {
    final box = Hive.box(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> delete(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  Future<void> clearAll() async {
    await Future.wait([
      clearBox(transactionsBoxName),
      clearBox(investmentsBoxName),
      clearBox(cardsBoxName),
      clearBox(settingsBoxName),
      clearBox(userBoxName),
    ]);
  }
}

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});
