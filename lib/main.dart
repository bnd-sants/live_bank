import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/design_system.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/providers/app_state_provider.dart';
import 'features/dashboard/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/investments/presentation/screens/investments_screen.dart';
import 'core/services/local_cache_service.dart';
import 'core/l10n/app_localizations.dart';

Future<void> main() async {
  // Configuração de logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  // Inicializa o binding do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Força orientação vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializa o Supabase
  try {
    await SupabaseConfig.initialize();
    debugPrint('Supabase inicializado com sucesso');
  } catch (e) {
    debugPrint('Erro ao inicializar Supabase: $e');
  }

  // Inicializa o Cache Local (Hive)
  try {
    final cacheService = LocalCacheService();
    await cacheService.init();
    debugPrint('Hive inicializado com sucesso');
  } catch (e) {
    debugPrint('Erro ao inicializar Hive: $e');
  }

  runApp(
    const ProviderScope(
      child: LiveBankApp(),
    ),
  );
}

class LiveBankApp extends ConsumerWidget {
  const LiveBankApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);

    final appState = ref.watch(appStateProvider);

    return MaterialApp(
      title: 'Live Bank',
      debugShowCheckedModeBanner: false,
      theme: DesignSystem.lightTheme,
      darkTheme: DesignSystem.darkTheme,
      themeMode: appState.themeMode,
      locale: appState.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizationsDelegate(),
      ],
      supportedLocales: const [
        Locale('pt', ''),
        Locale('en', ''),
      ],
      home: sessionState.when(
        data: (user) {
          debugPrint('Auth State Change: Data(user: ${user?.email})');
          return user != null ? const HomeScreen() : const LoginScreen();
        },
        loading: () {
          debugPrint('Auth State Change: Loading');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ),
          );
        },
        error: (error, stack) {
          debugPrint('Auth State Change: Error($error)');
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/investments': (context) => const InvestmentsScreen(),
      },
    );
  }
}
