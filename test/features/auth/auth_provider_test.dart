import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_bank/features/auth/presentation/providers/auth_provider.dart';
import 'package:live_bank/features/auth/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends AuthRepository {
  MockAuthRepository() : super(SupabaseClient('https://mock.supabase.co', 'mock-key'));

  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();

  User? _mockUser;
  bool _shouldThrow = false;
  Exception? _mockException;

  void setMockUser(User? user) {
    _mockUser = user;
    if (user != null) {
      _authStateController.add(AuthState(AuthChangeEvent.signedIn, Session(
        accessToken: 'mock-token',
        tokenType: 'bearer',
        user: user,
      )));
    } else {
      _authStateController.add(AuthState(AuthChangeEvent.signedOut, null));
    }
  }

  void setShouldThrow(Exception? exception) {
    _shouldThrow = exception != null;
    _mockException = exception;
  }

  @override
  User? get currentUser => _mockUser;

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    if (_shouldThrow) throw _mockException ?? Exception('Error');
    final user = User(
      id: 'mock-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    setMockUser(user);
    return AuthResponse(session: null, user: user);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    required String cpf,
  }) async {
    if (_shouldThrow) throw _mockException ?? Exception('Error');
    final user = User(
      id: 'mock-id',
      appMetadata: {},
      userMetadata: {'nome': nome},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    setMockUser(user);
    return AuthResponse(session: null, user: user);
  }

  @override
  Future<void> signOut() async {
    if (_shouldThrow) throw _mockException ?? Exception('Error');
    setMockUser(null);
  }
}

void main() {
  group('Auth Provider Tests', () {
    late MockAuthRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is unauthenticated when no user is logged in', () {
      final authState = container.read(sessionStateProvider);
      expect(authState, const AsyncValue<User?>.data(null));
    });

    test('Initial state is authenticated when user is already logged in', () {
      final user = User(
        id: 'mock-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      
      // Override repo with one that already has a user
      final loggedInRepo = MockAuthRepository()..setMockUser(user);
      final loggedInContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(loggedInRepo),
          sessionStateProvider.overrideWith((ref) => Stream.value(user)),
        ],
      );

      final authState = loggedInContainer.read(sessionStateProvider);
      expect(authState.value, user);
    });

    test('signIn updates state to authenticated', () async {
      final user = User(
        id: 'mock-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'test@test.com',
      );

      final customContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          sessionStateProvider.overrideWith((ref) => Stream.value(user)),
        ],
      );

      await customContainer.read(authProvider.notifier).signIn('test@test.com', 'password');
      
      final authState = customContainer.read(sessionStateProvider);
      expect(authState.value, isNotNull);
      expect(authState.value?.email, 'test@test.com');
    });

    test('signIn handles errors properly', () async {
      mockRepository.setShouldThrow(Exception('Invalid login'));
      
      try {
        await container.read(authProvider.notifier).signIn('test@test.com', 'password');
      } catch (e) {
        expect(e.toString(), contains('Invalid login'));
      }
      
      final authState = container.read(authProvider);
      expect(authState.hasError, true);
    });

    test('signOut updates state to unauthenticated', () async {
      final customContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          sessionStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      // Login first
      await customContainer.read(authProvider.notifier).signIn('test@test.com', 'password');

      // Then logout
      await customContainer.read(authProvider.notifier).signOut();
      final authState = customContainer.read(sessionStateProvider);
      expect(authState.value, isNull);
    });
  });
}
