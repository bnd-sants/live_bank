import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/features/cards/data/repositories/card_repository.dart';
import 'package:live_bank/features/cards/domain/models/card_model.dart';

final cardsProvider = AsyncNotifierProvider<CardsNotifier, List<CardModel>>(() {
  return CardsNotifier();
});

class CardsNotifier extends AsyncNotifier<List<CardModel>> {
  @override
  Future<List<CardModel>> build() async {
    final repository = ref.watch(cardRepositoryProvider);
    final result = await repository.fetchCards();
    
    return result.when(
      success: (cards) => cards,
      failure: (failure) => throw failure,
    );
  }

  Future<void> createCard(String label, {bool isEcommerce = false}) async {
    state = const AsyncValue.loading();
    final repository = ref.read(cardRepositoryProvider);
    final result = await repository.createVirtualCard(
      label: label,
      isEcommerce: isEcommerce,
    );

    result.when(
      success: (_) {
        ref.invalidateSelf();
      },
      failure: (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
    );
  }

  Future<void> toggleLock(String cardId, bool isLocked) async {
    final repository = ref.read(cardRepositoryProvider);
    final result = await repository.toggleCardLock(cardId, isLocked);

    result.when(
      success: (_) {
        // Atualização otimista no estado local
        state.whenData((cards) {
          state = AsyncValue.data(
            cards.map((c) => c.id == cardId ? c.copyWith(isLocked: isLocked) : c).toList(),
          );
        });
      },
      failure: (failure) {
        // Se falhar, recarrega do banco
        ref.invalidateSelf();
      },
    );
  }

  Future<void> deleteCard(String cardId) async {
    final repository = ref.read(cardRepositoryProvider);
    final result = await repository.deleteCard(cardId);

    result.when(
      success: (_) {
        state.whenData((cards) {
          state = AsyncValue.data(
            cards.where((c) => c.id != cardId).toList(),
          );
        });
      },
      failure: (failure) {
        ref.invalidateSelf();
      },
    );
  }
}
