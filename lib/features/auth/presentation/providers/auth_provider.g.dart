// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionStateHash() => r'dd662e4165721774dcbc8ca01005f785131b92cc';

/// See also [sessionState].
@ProviderFor(sessionState)
final sessionStateProvider = AutoDisposeStreamProvider<User?>.internal(
  sessionState,
  name: r'sessionStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sessionStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SessionStateRef = AutoDisposeStreamProviderRef<User?>;
String _$authHash() => r'f75785168e493922bd39e5cf5cde0b4a66e3ad12';

/// See also [Auth].
@ProviderFor(Auth)
final authProvider =
    AutoDisposeNotifierProvider<Auth, AsyncValue<void>>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Auth = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
