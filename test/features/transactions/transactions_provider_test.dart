import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/core/error/failure.dart';
import 'package:live_bank/core/utils/result.dart';
import 'package:live_bank/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:live_bank/features/transactions/data/repositories/transaction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_bank/core/services/local_cache_service.dart';

class MockTransactionRepository extends TransactionRepository {
  MockTransactionRepository() : super(SupabaseClient('https://mock.supabase.co', 'mock-key'), LocalCacheService());

  bool _shouldFail = false;
  Failure? _mockFailure;

  void setShouldFail(Failure? failure) {
    _shouldFail = failure != null;
    _mockFailure = failure;
  }

  @override
  Future<Result<Map<String, dynamic>>> searchRecipient(String key, String type) async {
    if (_shouldFail) return Result.failure(_mockFailure ?? const ValidationFailure('Error'));
    return Result.success({
      'user_id': 'mock-recipient-id',
      'nome': 'João Silva',
      'cpf': '12345678900',
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> executeTransfer({
    required String toUserId,
    required double amount,
    String? description,
  }) async {
    if (_shouldFail) return Result.failure(_mockFailure ?? const ServerFailure('Error'));
    return Result.success({
      'success': true,
      'transaction_id': 'tx-1234',
    });
  }
}

void main() {
  group('Transactions Provider Tests', () {
    late MockTransactionRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockTransactionRepository();
      container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('recipientSearchTermProvider initial state', () {
      final term = container.read(recipientSearchTermProvider);
      expect(term, '');
    });

    test('transferAmountProvider initial state', () {
      final amount = container.read(transferAmountProvider);
      expect(amount, 0.0);
    });

    test('recipientSearchProvider search success', () async {
      await container.read(recipientSearchProvider.notifier).search('12345678900', 'cpf');
      
      final state = container.read(recipientSearchProvider);
      expect(state.value, isNotNull);
      expect(state.value?['nome'], 'João Silva');
    });

    test('recipientSearchProvider search failure', () async {
      mockRepository.setShouldFail(const ValidationFailure('Not found'));
      
      await container.read(recipientSearchProvider.notifier).search('123', 'cpf');
      
      final state = container.read(recipientSearchProvider);
      expect(state.hasError, true);
      expect(state.error, 'Not found');
    });

    test('transferExecutionProvider execute success', () async {
      await container.read(transferExecutionProvider.notifier).execute(
        toUserId: 'recipient-id',
        amount: 100.0,
      );
      
      final state = container.read(transferExecutionProvider);
      expect(state.value, isNotNull);
      expect(state.value?['success'], true);
      expect(state.value?['transaction_id'], 'tx-1234');
    });

    test('transferExecutionProvider execute failure', () async {
      mockRepository.setShouldFail(const InsufficientBalanceFailure('Insufficient balance'));
      
      await container.read(transferExecutionProvider.notifier).execute(
        toUserId: 'recipient-id',
        amount: 10000.0,
      );
      
      final state = container.read(transferExecutionProvider);
      expect(state.hasError, true);
      expect(state.error, 'Insufficient balance');
    });
  });
}
