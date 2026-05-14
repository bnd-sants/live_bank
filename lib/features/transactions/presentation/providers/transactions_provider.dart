import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/core/utils/result.dart';
import 'package:live_bank/features/transactions/data/repositories/transaction_repository.dart';

final transferAmountProvider = StateProvider<double>((ref) => 0.0);
final pixKeyTypeProvider = StateProvider<String>((ref) => 'cpf');
final recipientSearchTermProvider = StateProvider<String>((ref) => '');

final recipientSearchProvider = AsyncNotifierProvider<RecipientSearchNotifier, Map<String, dynamic>?>(() {
  return RecipientSearchNotifier();
});

class RecipientSearchNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return null;
  }

  Future<void> search(String key, String type) async {
    state = const AsyncValue.loading();
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.searchRecipient(key, type);
    
    result.when(
      success: (data) => state = AsyncValue.data(data),
      failure: (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final transferExecutionProvider = AsyncNotifierProvider<TransferExecutionNotifier, Map<String, dynamic>?>(() {
  return TransferExecutionNotifier();
});

class TransferExecutionNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return null;
  }

  Future<void> execute({
    required String toUserId,
    required double amount,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.executeTransfer(
      toUserId: toUserId,
      amount: amount,
      description: description,
    );

    result.when(
      success: (data) => state = AsyncValue.data(data),
      failure: (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }
}
