import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live_bank/core/providers/supabase_provider.dart';
import 'package:live_bank/core/error/failure.dart';
import 'package:live_bank/core/utils/result.dart';
import 'package:live_bank/features/transactions/domain/models/transaction_model.dart';
import 'package:live_bank/core/services/local_cache_service.dart';
import 'dart:convert';

class TransactionRepository {
  final SupabaseClient _supabase;
  final LocalCacheService _cache;

  TransactionRepository(this._supabase, this._cache);

  Future<Result<double>> fetchBalance() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Sessão expirada. Por favor, faça login novamente.'));
      }

      try {
        final data = await _supabase
            .from('accounts')
            .select('balance')
            .eq('user_id', userId)
            .maybeSingle();

        final balance = (data?['balance'] as num?)?.toDouble() ?? 0.0;
        
        // Salva no cache
        await _cache.put(LocalCacheService.userBoxName, 'balance', balance);
        
        return Result.success(balance);
      } catch (e) {
        // Fallback para cache
        final cachedBalance = _cache.get(LocalCacheService.userBoxName, 'balance');
        if (cachedBalance != null) {
          return Result.success(cachedBalance as double);
        }
        rethrow;
      }
    } catch (e) {
      return Result.failure(ServerFailure('Não conseguimos recuperar seu saldo agora.', originalError: e));
    }
  }

  Future<Result<List<TransactionModel>>> fetchHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Acesse sua conta para ver o extrato.'));
      }

      try {
        final data = await _supabase
            .from('transfers')
            .select()
            .eq('user_id', userId)
            .order('data', ascending: false);

        final transactions = (data as List)
            .map((json) => TransactionModel.fromJson(json))
            .toList();
            
        // Salva no cache
        await _cache.put(LocalCacheService.transactionsBoxName, 'history', jsonEncode(data));
            
        return Result.success(transactions);
      } catch (e) {
        // Fallback para cache
        final cachedHistory = _cache.get(LocalCacheService.transactionsBoxName, 'history');
        if (cachedHistory != null) {
          final decoded = jsonDecode(cachedHistory) as List;
          final transactions = decoded.map((json) => TransactionModel.fromJson(json)).toList();
          return Result.success(transactions);
        }
        rethrow;
      }
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao carregar seu extrato bancário.', originalError: e));
    }
  }

  Future<Result<Map<String, dynamic>>> searchRecipient(String key, String type) async {
    try {
      final query = _supabase.from('users').select('user_id, nome, cpf, email, telefone');
      
      PostgrestFilterBuilder filter;
      switch (type) {
        case 'cpf':
          filter = query.eq('cpf', key.replaceAll(RegExp(r'[^0-9]'), ''));
          break;
        case 'email':
          filter = query.eq('email', key.trim().toLowerCase());
          break;
        case 'celular':
          filter = query.eq('telefone', key.replaceAll(RegExp(r'[^0-9]'), ''));
          break;
        default:
          return Result.failure(const ValidationFailure('Tipo de chave Pix inválido.'));
      }

      final data = await filter.maybeSingle();
      if (data == null) {
        return Result.failure(const ValidationFailure('Destinatário não encontrado. Verifique os dados.'));
      }

      final userId = _supabase.auth.currentUser?.id;
      if (data['user_id'] == userId) {
        return Result.failure(const ValidationFailure('Você não pode realizar uma transferência para si mesmo.'));
      }

      return Result.success(data);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao buscar o contato.', originalError: e));
    }
  }

  Future<Result<Map<String, dynamic>>> executeTransfer({
    required String toUserId,
    required double amount,
    String? description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Autentique-se para realizar transferências.'));
      }

      if (userId == toUserId) {
        return Result.failure(const ValidationFailure('Você não pode transferir dinheiro para si mesmo.'));
      }

      final response = await _supabase.rpc('transfer_money', params: {
        'p_from_user_id': userId,
        'p_to_user_id': toUserId,
        'p_amount': amount.toString(),
        'p_description': description ?? 'Transferência via Live Bank',
      });

      final responseData = response as Map<String, dynamic>;
      if (responseData['success'] != true) {
        final errorMsg = responseData['error'] ?? 'Não foi possível completar a transferência.';
        return Result.failure(ServerFailure(errorMsg));
      }

      return Result.success(responseData);
    } on PostgrestException catch (e) {
      if (e.message.contains('insufficient')) {
        return Result.failure(const InsufficientBalanceFailure('Saldo insuficiente para completar esta operação.'));
      }
      return Result.failure(DatabaseFailure('Erro no processamento bancário: ${e.message}', originalError: e));
    } catch (e) {
      return Result.failure(ServerFailure('Ocorreu um erro inesperado na transferência.', originalError: e));
    }
  }

  Future<Result<void>> simulateDeposit(double amount) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return Result.failure(const AuthFailure('Usuário não autenticado.'));

      // Primeiro verifica se a conta existe
      final account = await _supabase
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (account == null) {
        // Cria a conta com o saldo inicial
        await _supabase.from('accounts').insert({
          'user_id': userId,
          'balance': amount,
        });
      } else {
        // Atualiza o saldo existente
        final currentBalance = (account['balance'] as num).toDouble();
        await _supabase
            .from('accounts')
            .update({'balance': currentBalance + amount})
            .eq('user_id', userId);
      }

      // Adiciona uma transação fictícia no histórico
      await _supabase.from('transfers').insert({
        'user_id': userId,
        'description': 'Depósito Simulado (Teste)',
        'valor': amount,
        'destinatario': 'Minha Conta',
        'data': DateTime.now().toIso8601String(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao simular depósito: $e'));
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final cache = ref.watch(localCacheServiceProvider);
  return TransactionRepository(supabase, cache);
});
