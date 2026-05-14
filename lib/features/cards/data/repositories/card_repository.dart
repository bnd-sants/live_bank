import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_bank/core/providers/supabase_provider.dart';
import 'package:live_bank/core/error/failure.dart';
import 'package:live_bank/core/utils/result.dart';
import 'package:live_bank/features/cards/domain/models/card_model.dart';
import 'package:live_bank/core/services/local_cache_service.dart';
import 'dart:convert';

class CardRepository {
  final SupabaseClient _supabase;
  final LocalCacheService _cache;

  CardRepository(this._supabase, this._cache);

  Future<Result<List<CardModel>>> fetchCards() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Faça login para gerenciar seus cartões.'));
      }

      try {
        final data = await _supabase
            .from('cards')
            .select()
            .eq('user_id', userId)
            .order('created_at');

        final cards = (data as List).map((json) => CardModel.fromJson(json)).toList();
        
        // Salva no cache
        await _cache.put(LocalCacheService.cardsBoxName, 'my_cards', jsonEncode(data));
        
        return Result.success(cards);
      } catch (e) {
        // Fallback para cache
        final cachedCards = _cache.get(LocalCacheService.cardsBoxName, 'my_cards');
        if (cachedCards != null) {
          final decoded = jsonDecode(cachedCards) as List;
          final cards = decoded.map((json) => CardModel.fromJson(json)).toList();
          return Result.success(cards);
        }
        rethrow;
      }
    } catch (e) {
      return Result.failure(ServerFailure('Não foi possível carregar seus cartões.', originalError: e));
    }
  }

  Future<Result<CardModel>> createVirtualCard({
    required String label,
    bool isEcommerce = false,
  }) async {
    final result = await createMultipleVirtualCards(count: 1, baseLabel: label, isEcommerce: isEcommerce);
    return result.fold(
      (cards) => Result.success(cards.first),
      (failure) => Result.failure(failure),
    );
  }

  /// Cria múltiplos cartões virtuais em lote. Ideal para cartões de e-commerce descartáveis ou múltiplos usos.
  Future<Result<List<CardModel>>> createMultipleVirtualCards({
    required int count,
    required String baseLabel,
    bool isEcommerce = true,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure('Sessão inválida.'));
      }

      final random = Random();
      final holderName = (user.userMetadata?['nome'] ?? 'CLIENTE LIVE BANK').toUpperCase();
      final now = DateTime.now();
      final expiryDate = '${now.month.toString().padLeft(2, '0')}/${(now.year + 5).toString().substring(2)}';

      final List<Map<String, dynamic>> batchData = [];

      for (int i = 0; i < count; i++) {
        final lastFour = (1000 + random.nextInt(9000)).toString();
        final cvv = (100 + random.nextInt(900)).toString();
        final label = count > 1 ? '$baseLabel ${i + 1}' : baseLabel;

        batchData.add({
          'user_id': user.id,
          'last_four': lastFour,
          'holder_name': holderName,
          'card_type': 'virtual',
          'is_locked': false,
          'cvv': cvv,
          'expiry_date': expiryDate,
          'label': isEcommerce ? '🛒 $label' : '🌐 $label',
        });
      }

      final data = await _supabase
          .from('cards')
          .insert(batchData)
          .select();

      final cards = (data as List).map((json) => CardModel.fromJson(json)).toList();
      return Result.success(cards);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao gerar cartões virtuais.', originalError: e));
    }
  }

  Future<Result<void>> toggleCardLock(String cardId, bool isLocked) async {
    try {
      await _supabase
          .from('cards')
          .update({'is_locked': isLocked})
          .eq('id', cardId);

      return Result.success(null);
    } catch (e) {
      final action = isLocked ? 'bloquear' : 'desbloquear';
      return Result.failure(ServerFailure('Não foi possível $action o cartão agora.', originalError: e));
    }
  }

  Future<Result<void>> deleteCard(String cardId) async {
    try {
      // Nota: No banco de dados real, poderíamos ter uma deleção lógica (soft delete)
      await _supabase
          .from('cards')
          .delete()
          .eq('id', cardId);

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao cancelar o cartão virtual.', originalError: e));
    }
  }
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final cache = ref.watch(localCacheServiceProvider);
  return CardRepository(supabase, cache);
});
