import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/core/utils/result.dart';
import 'package:live_bank/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:live_bank/features/transactions/data/repositories/transaction_repository.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import 'package:live_bank/features/profile/data/repositories/user_repository.dart';
import 'package:mockito/mockito.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {
  @override
  Future<Result<double>> fetchBalance() async {
    return Result.success(1250.50);
  }

  @override
  Future<Result<List<TransactionModel>>> fetchHistory() async {
    return Result.success([
      TransactionModel(
        id: '1',
        description: 'Mercado',
        amount: 50.0,
        date: DateTime.now(),
        type: 'debit',
      ),
    ]);
  }
}

class MockUserRepository extends Mock implements UserRepository {
  @override
  Future<Result<Map<String, dynamic>>> getUserProfile() async {
    return Result.success({'nome': 'Bernardo', 'email': 'bernardo@example.com'});
  }
}

void main() {
  group('Dashboard Providers Tests', () {
    late MockTransactionRepository mockTransactionRepository;
    late MockUserRepository mockUserRepository;
    late ProviderContainer container;

    setUp(() {
      mockTransactionRepository = MockTransactionRepository();
      mockUserRepository = MockUserRepository();
      container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockTransactionRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('balanceProvider returns correct balance', () async {
      final balance = await container.read(balanceProvider.future);
      expect(balance, 1250.50);
    });

    test('transactionsProvider returns transaction list', () async {
      final transactions = await container.read(transactionsProvider.future);
      expect(transactions.length, 1);
      expect(transactions.first.description, 'Mercado');
    });

    test('userProfileProvider returns user profile', () async {
      final profile = await container.read(userProfileProvider.future);
      expect(profile['nome'], 'Bernardo');
      expect(profile['email'], 'bernardo@example.com');
    });
  });
}
