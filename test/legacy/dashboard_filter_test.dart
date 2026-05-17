import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:live_bank/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:live_bank/features/auth/presentation/providers/auth_provider.dart';
import 'package:live_bank/features/auth/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';

// Mock do AuthRepository sem instanciar SupabaseClient real
class MockAuthRepository extends Mock implements AuthRepository {
  User? _user;
  void setMockUser(User? user) => _user = user;
  
  @override
  User? get currentUser => _user;
  
  @override
  Stream<AuthState> get authStateChanges => Stream.value(const AuthState(AuthChangeEvent.initialSession, null));
  
  @override
  Future<void> signOut() async {
    _user = null;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('Filtro de transferências', () {
    final historico = [
      TransactionModel(id: '1', description: 'João', amount: 100.0, date: DateTime.parse('2024-05-01'), type: 'debit'),
      TransactionModel(id: '2', description: 'Maria', amount: 250.0, date: DateTime.parse('2024-05-02'), type: 'credit'),
      TransactionModel(id: '3', description: 'José', amount: 50.0, date: DateTime.parse('2024-05-03'), type: 'debit'),
      TransactionModel(id: '4', description: 'Ana', amount: 300.0, date: DateTime.parse('2024-05-04'), type: 'credit'),
    ];

    Widget createWidgetUnderTest(MockAuthRepository mockAuth) {
      return ProviderScope(
        overrides: [
          balanceProvider.overrideWith((ref) => Future.value(1000.0)),
          transactionsProvider.overrideWith((ref) => Future.value(historico)),
          authProvider.overrideWith(() => Auth()),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('pt', 'BR'),
          ],
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('Filtra por destinatário', (tester) async {
      final mockAuth = MockAuthRepository();
      mockAuth.setMockUser(User(
        id: 'test-uid',
        appMetadata: {},
        userMetadata: {'nome': 'Test User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'test@example.com',
      ));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };

      try {
        SharedPreferences.setMockInitialValues({'showTransactions': true});
        
        await tester.pumpWidget(createWidgetUnderTest(mockAuth));
        await tester.pumpAndSettle();
        
        final listView = find.byType(ListView);
        await tester.drag(listView, const Offset(0, -600));
        await tester.pumpAndSettle();
        
        final textFields = find.byType(TextField);
        expect(textFields, findsWidgets);

        final searchField = textFields.first;
        await tester.enterText(searchField, 'Maria');
        await tester.pumpAndSettle();
        
        expect(find.text('Maria'), findsWidgets);
        expect(find.text('João'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('Filtra por tipo de transação', (tester) async {
      final mockAuth = MockAuthRepository();
      mockAuth.setMockUser(User(
        id: 'test-uid',
        appMetadata: {},
        userMetadata: {'nome': 'Test User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'test@example.com',
      ));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };

      try {
        SharedPreferences.setMockInitialValues({'showTransactions': true});
        
        await tester.pumpWidget(createWidgetUnderTest(mockAuth));
        await tester.pumpAndSettle();
        
        final listView = find.byType(ListView);
        await tester.drag(listView, const Offset(0, -600));
        await tester.pumpAndSettle();
        
        final dropdownFinder = find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>);
        expect(dropdownFinder, findsOneWidget);
        
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        
        final creditoFinder = find.text('Crédito').last;
        await tester.tap(creditoFinder);
        await tester.pumpAndSettle();
        
        expect(find.text('Maria'), findsWidgets);
        expect(find.text('Ana'), findsWidgets);
        expect(find.text('João'), findsNothing);
        expect(find.text('José'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });
}
