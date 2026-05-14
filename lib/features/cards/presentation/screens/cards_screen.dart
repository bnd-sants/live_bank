import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/features/cards/presentation/providers/cards_provider.dart';
import 'package:live_bank/features/cards/domain/models/card_model.dart';
import 'package:live_bank/core/theme/app_colors.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meus Cartões'),
        backgroundColor: Colors.transparent,
      ),
      body: cardsAsync.when(
        data: (cards) => cards.isEmpty
            ? _buildEmptyState(context, ref)
            : _buildCardsList(context, ref, cards),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar cartões: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(cardsProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCardDialog(context, ref),
        label: const Text('Novo Cartão Virtual'),
        icon: const Icon(Icons.add_card),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Você ainda não possui cartões virtuais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie um agora para fazer compras online com segurança.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(BuildContext context, WidgetRef ref, List<CardModel> cards) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildCardItem(context, ref, card);
      },
    );
  }

  Widget _buildCardItem(BuildContext context, WidgetRef ref, CardModel card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: card.isLocked
                ? [AppColors.grey500, AppColors.grey400]
                : (card.label?.contains('🛒') ?? false)
                    ? [AppColors.accent, AppColors.accent.withOpacity(0.8)]
                    : AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (card.label ?? 'CARTÃO').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Icon(
                    card.isLocked ? Icons.lock : Icons.contactless,
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                '**** **** **** ${card.lastFour}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 4,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TITULAR',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      Text(
                        card.holderName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VALIDADE',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      Text(
                        card.expiryDate,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CVV',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      Text(
                        card.isLocked ? '***' : card.cvv ?? '***',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => ref.read(cardsProvider.notifier).toggleLock(card.id, !card.isLocked),
                    icon: Icon(card.isLocked ? Icons.lock_open : Icons.lock, size: 18),
                    label: Text(card.isLocked ? 'Desbloquear' : 'Bloquear'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(context, ref, card),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCardDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'Compras Online');
    bool isEcommerce = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo Cartão Virtual'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Apelido do Cartão',
                  hintText: 'Ex: Amazon, Mercado Livre, Assinaturas',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: isEcommerce,
                onChanged: (val) => setState(() => isEcommerce = val),
                activeColor: AppColors.primary,
                title: const Text('Uso em E-commerce', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Adiciona ícone e cor diferenciada para compras online.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final label = controller.text.trim();
                if (label.isNotEmpty) {
                  ref.read(cardsProvider.notifier).createCard(label, isEcommerce: isEcommerce);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, CardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Cartão?'),
        content: Text('Tem certeza que deseja excluir o cartão "${card.label}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cardsProvider.notifier).deleteCard(card.id);
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
