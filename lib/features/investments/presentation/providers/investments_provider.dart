import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/features/investments/data/repositories/investment_repository.dart';
import 'package:live_bank/features/investments/domain/models/investment_model.dart';

// Provedor para a lista de investimentos do usuário
class InvestmentsNotifier extends AsyncNotifier<List<InvestmentModel>> {
  @override
  FutureOr<List<InvestmentModel>> build() async {
    final repository = ref.watch(investmentRepositoryProvider);
    final result = await repository.fetchInvestments();
    
    return result.fold(
      (investments) => investments,
      (failure) => throw failure,
    );
  }

  Future<void> invest({
    required String assetType,
    required String assetName,
    required double amount,
    required double currentPrice,
  }) async {
    state = const AsyncValue.loading();
    final repository = ref.read(investmentRepositoryProvider);
    final result = await repository.invest(
      assetType: assetType,
      assetName: assetName,
      amount: amount,
      currentPrice: currentPrice,
    );

    if (result.isSuccess) {
      ref.invalidateSelf();
    } else {
      state = AsyncValue.error(result.failure!, StackTrace.current);
    }
  }
}

final investmentsProvider = AsyncNotifierProvider<InvestmentsNotifier, List<InvestmentModel>>(
  InvestmentsNotifier.new,
);

// Provedor para cotações atuais do mercado
final quotesProvider = FutureProvider<Map<String, double>>((ref) async {
  final repository = ref.watch(investmentRepositoryProvider);
  final result = await repository.fetchMarketQuotes();
  
  return result.fold(
    (quotes) => quotes,
    (failure) => throw failure,
  );
});

// Provedor para histórico de cotações (7 dias)
final exchangeHistoryProvider = FutureProvider<Map<String, List<MapEntry<DateTime, double>>>>((ref) async {
  final repository = ref.watch(investmentRepositoryProvider);
  final result = await repository.fetchExchangeHistory();
  
  return result.fold(
    (history) => history,
    (failure) => throw failure,
  );
});
