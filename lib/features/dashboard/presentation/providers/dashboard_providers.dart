import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/features/transactions/data/repositories/transaction_repository.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import 'package:live_bank/features/profile/data/repositories/user_repository.dart';

// Provider para o saldo do usuário
final balanceProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final result = await repository.fetchBalance();
  return result.fold(
    (balance) => balance,
    (failure) => throw failure,
  );
});

// Provider para o histórico de transações
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final result = await repository.fetchHistory();
  return result.fold(
    (transactions) => transactions,
    (failure) => throw failure,
  );
});

// Provider para o perfil do usuário
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  final result = await repository.getUserProfile();
  return result.fold(
    (profile) => profile,
    (failure) => throw failure,
  );
});
