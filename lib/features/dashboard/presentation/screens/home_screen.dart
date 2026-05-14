import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/features/auth/presentation/providers/auth_provider.dart';
import 'package:live_bank/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:live_bank/core/providers/app_state_provider.dart';
import 'package:live_bank/widgets/saldo_card.dart';
import 'package:live_bank/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:live_bank/features/transactions/presentation/screens/transfer_screen.dart';
import 'package:live_bank/features/settings/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _saldoVisivel = true;

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(balanceProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(transactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bank'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(),
          ),
        ],
      ),
      drawer: _buildDrawer(context, userProfileAsync),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userProfileAsync.when(
                data: (profile) => Text(
                  'Olá, ${profile['nome']?.split(' ').first ?? 'Usuário'}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                loading: () => const Text('Carregando...', style: TextStyle(fontSize: 24)),
                error: (_, __) => const Text('Olá!', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 10),
              SaldoCard(
                saldo: balanceAsync.value ?? 0.0,
                visivel: _saldoVisivel,
                isLoading: balanceAsync.isLoading,
                error: balanceAsync.hasError ? 'Erro ao carregar saldo' : null,
                onToggleVisibilidade: () => setState(() => _saldoVisivel = !_saldoVisivel),
              ),
              const SizedBox(height: 20),
              _buildMainActions(),
              const SizedBox(height: 20),
              const Text(
                'Serviços',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildServiceGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AsyncValue<Map<String, dynamic>> userProfileAsync) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          userProfileAsync.when(
            data: (profile) => UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF20232A)),
              accountEmail: Text(profile['email'] ?? ''),
              accountName: Text(
                profile['nome'] ?? 'Usuário',
                style: const TextStyle(color: Colors.white),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: profile['foto'] != null ? NetworkImage(profile['foto']) : null,
                child: profile['foto'] == null ? Text((profile['nome'] ?? 'U')[0].toUpperCase()) : null,
              ),
            ),
            loading: () => const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF20232A)),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF20232A)),
              child: Text('Erro ao carregar perfil'),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Histórico',
            onTap: _navigateToDashboard,
          ),
          _buildThemeToggleItem(),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Perfil',
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Configurações',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          _buildLanguageItem(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Sair',
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleItem() {
    final appState = ref.watch(appStateProvider);
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Tema'),
      trailing: Text(appState.themeMode == ThemeMode.dark ? 'Escuro' : 'Claro'),
      onTap: () => ref.read(appStateProvider.notifier).toggleTheme(),
    );
  }

  Widget _buildLanguageItem() {
    final appState = ref.watch(appStateProvider);
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text('Idioma: ${appState.locale.languageCode == 'en' ? 'English' : 'Português'}'),
      onTap: () {
        final newLocale = appState.locale.languageCode == 'pt' ? const Locale('en') : const Locale('pt');
        ref.read(appStateProvider.notifier).setLocale(newLocale);
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildMainActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.send,
            text: 'Transferir',
            onPressed: _navigateToTransfer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.qr_code,
            text: 'PIX',
            onPressed: () => _showSuccessSnackbar('PIX em breve!'),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildServiceCard(
          icon: Icons.credit_card,
          title: 'Cartões',
          onTap: () => Navigator.pushNamed(context, '/cards'),
        ),
        _buildServiceCard(
          icon: Icons.trending_up,
          title: 'Investimentos',
          onTap: () => Navigator.pushNamed(context, '/investments'),
        ),
        _buildServiceCard(
          icon: Icons.receipt_long,
          title: 'Comprovantes',
          onTap: () => _showSuccessSnackbar('Comprovantes em breve!'),
        ),
        _buildServiceCard(
          icon: Icons.help_outline,
          title: 'Ajuda',
          onTap: () => _showSuccessSnackbar('Suporte em breve!'),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _navigateToDashboard() async {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(),
      ),
    );
  }

  Future<void> _navigateToTransfer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    );

    if (result == true) {
      ref.invalidate(balanceProvider);
      _showSuccessSnackbar('Transferência realizada com sucesso!');
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await ref.read(authProvider.notifier).signOut();
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
