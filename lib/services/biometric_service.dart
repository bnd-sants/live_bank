import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logging/logging.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal() {
    _init();
  }

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyEncryptedCreds = 'biometric_credentials_encrypted';
  
  final _encryptionKey = encrypt.Key.fromLength(32);
  final _iv = encrypt.IV.fromLength(16);
  final _logger = Logger('BiometricService');
  bool _isInitialized = false;
  
  Future<void> _init() async {
    try {
      await isBiometricAvailable();
      _isInitialized = true;
    } catch (e) {
      _logger.severe('Erro ao inicializar BiometricService', e);
      rethrow;
    }
  }

  // Gera uma chave de criptografia estável baseada no ID do dispositivo
  Future<encrypt.Key> _getSecureKey() async {
    String deviceId = 'live_bank_fallback_stable_salt';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        deviceId = 'live_bank_web_salt';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'live_bank_ios_fallback';
      }
    } catch (e) {
      _logger.warning('Erro ao obter DeviceInfo para chave estável: $e');
    }
    final salt = 'live_bank_premium_salt_2026_!@#';
    final bytes = utf8.encode(deviceId + salt);
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  // Salva credenciais criptografadas localmente
  Future<void> saveCredentials(String email, String password) async {
    try {
      final key = await _getSecureKey();
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      final dataToEncrypt = '$email:$password';
      final encrypted = encrypter.encrypt(dataToEncrypt, iv: iv);
      
      final savedString = '${iv.base64}:${encrypted.base64}';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEncryptedCreds, savedString);
      _logger.info('Credenciais salvas de forma segura criptografada');
    } catch (e) {
      _logger.severe('Erro ao salvar credenciais com biometria: $e');
    }
  }

  // Recupera e descriptografa as credenciais
  Future<Map<String, String>?> getCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_keyEncryptedCreds);
      
      if (savedString == null || !savedString.contains(':')) {
        _logger.info('Nenhuma credencial biométrica encontrada ou inválida');
        return null;
      }
      
      final parts = savedString.split(':');
      if (parts.length != 2) return null;
      
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedBase64 = parts[1];
      
      final key = await _getSecureKey();
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
      
      if (!decrypted.contains(':')) return null;
      
      final credParts = decrypted.split(':');
      if (credParts.length < 2) return null;
      
      final email = credParts[0];
      final password = credParts.sublist(1).join(':');
      
      return {'email': email, 'password': password};
    } catch (e) {
      _logger.severe('Erro ao recuperar ou descriptografar credenciais: $e');
      return null;
    }
  }

  // Limpa as credenciais salvas
  Future<void> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyEncryptedCreds);
      _logger.info('Credenciais biométricas removidas com sucesso');
    } catch (e) {
      _logger.severe('Erro ao limpar credenciais biométricas: $e');
    }
  }

  // Verifica se o dispositivo suporta biometria
  Future<bool> isBiometricAvailable() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isWindows) {
        _logger.info('Windows não suporta autenticação biométrica nativa');
        return false;
      }

      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      
      _logger.info('''
        Biometria disponível:
        - Pode verificar biometria: $canCheckBiometrics
        - Dispositivo suportado: $isDeviceSupported
      ''');

      if (!canCheckBiometrics || !isDeviceSupported) {
        _logger.warning('Dispositivo não suporta biometria ou não pode verificar');
        return false;
      }

      return canCheckBiometrics || isDeviceSupported;
    } on PlatformException catch (e) {
      _logger.severe('Erro ao verificar disponibilidade de biometria', e);
      return false;
    } catch (e) {
      _logger.severe('Erro inesperado ao verificar biometria', e);
      return false;
    }
  }

  // Realiza a autenticação biométrica
  Future<bool> authenticate({String? localizedReason}) async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      
      if (!await isBiometricAvailable()) {
        _logger.warning('Biometria não disponível para autenticação');
        return false;
      }

      _logger.info('Iniciando autenticação biométrica...');
      
      final result = await _auth.authenticate(
        localizedReason: localizedReason ?? 'Autentique-se para acessar o aplicativo',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );
      
      _logger.info('Resultado da autenticação: $result');
      return result;
      
    } on PlatformException catch (e) {
      _logger.severe('Erro na autenticação biométrica', e);
      return false;
    } catch (e) {
      _logger.severe('Erro inesperado na autenticação biométrica', e);
      return false;
    }
  }

  // Verifica se a biometria está habilitada nas preferências
  Future<bool> isBiometricEnabled() async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      if (kIsWeb) {
        final isEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
        _logger.info('Biometria ${isEnabled ? 'habilitada' : 'desabilitada'} nas preferências');
        return isEnabled;
      }
      
      if (Platform.isWindows) {
        final encrypted = prefs.getString('${_keyBiometricEnabled}_encrypted');
        if (encrypted == null) {
          _logger.info('Nenhuma configuração de biometria encontrada');
          return false;
        }

        try {
          final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
          final decrypted = encrypter.decrypt64(encrypted, iv: _iv);
          final isEnabled = decrypted == 'true';
          _logger.info('Biometria ${isEnabled ? 'habilitada' : 'desabilitada'} nas preferências');
          return isEnabled;
        } catch (e) {
          _logger.warning('Erro ao descriptografar preferência de biometria', e);
          return false;
        }
      } else {
        final isEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
        _logger.info('Biometria ${isEnabled ? 'habilitada' : 'desabilitada'} nas preferências');
        return isEnabled;
      }
    } catch (e) {
      _logger.severe('Erro ao verificar status da biometria', e);
      return false;
    }
  }

  // Habilita ou desabilita a biometria nas preferências
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      
      _logger.info('${enabled ? 'Habilitando' : 'Desabilitando'} biometria...');
      
      if (enabled) {
        final isAvailable = await isBiometricAvailable();
        if (!isAvailable) {
          _logger.warning('Não é possível habilitar biometria: recurso não disponível');
          return false;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      bool saveSuccess = false;

      if (kIsWeb) {
        saveSuccess = await prefs.setBool(_keyBiometricEnabled, enabled);
      } else if (Platform.isWindows) {
        try {
          final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
          final encrypted = encrypter.encrypt(enabled.toString(), iv: _iv);
          saveSuccess = await prefs.setString(
            '${_keyBiometricEnabled}_encrypted', 
            encrypted.base64
          );
        } catch (e) {
          _logger.severe('Erro ao criptografar preferência de biometria', e);
          return false;
        }
      } else {
        saveSuccess = await prefs.setBool(_keyBiometricEnabled, enabled);
      }
      
      if (saveSuccess) {
        _logger.info('Biometria ${enabled ? 'habilitada' : 'desabilitada'} com sucesso');
      } else {
        _logger.warning('Falha ao salvar preferência de biometria');
      }
      
      return saveSuccess;
      
    } catch (e) {
      _logger.severe('Erro ao ${enabled ? 'habilitar' : 'desabilitar'} biometria', e);
      return false;
    }
  }
  
  // Verifica se o dispositivo tem biometria configurada
  Future<bool> hasEnrolledBiometrics() async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      
      if (kIsWeb) return false;
      if (Platform.isWindows) return false;
      
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
      
    } catch (e) {
      _logger.severe('Erro ao verificar biometrias cadastradas', e);
      return false;
    }
  }
}
