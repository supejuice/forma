import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ApiKeyStorage {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

final class SecureApiKeyStorage implements ApiKeyStorage {
  SecureApiKeyStorage(this._secureStorage);

  static const String _storageKey = 'mistral_api_key';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> clear() async {
    await _secureStorage.delete(key: _storageKey);
  }

  @override
  Future<String?> read() async {
    return _secureStorage.read(key: _storageKey);
  }

  @override
  Future<void> write(String value) async {
    await _secureStorage.write(key: _storageKey, value: value);
  }
}

final class SharedPrefsApiKeyStorage implements ApiKeyStorage {
  static const String _storageKey = 'mistral_api_key';

  @override
  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  @override
  Future<String?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey);
  }

  @override
  Future<void> write(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, value);
  }
}

final class ResilientApiKeyStorage implements ApiKeyStorage {
  const ResilientApiKeyStorage({required this.primary, required this.fallback});

  final ApiKeyStorage primary;
  final ApiKeyStorage fallback;

  @override
  Future<void> clear() async {
    await Future.wait<void>(<Future<void>>[
      primary.clear().timeout(const Duration(seconds: 2), onTimeout: () {}),
      fallback.clear().timeout(const Duration(seconds: 2), onTimeout: () {}),
    ]);
  }

  @override
  Future<String?> read() async {
    try {
      final String? value = await primary.read().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (value != null && value.trim().isNotEmpty) {
        unawaited(fallback.write(value));
        return value;
      }
    } catch (_) {
      // Fall back below.
    }
    return fallback.read();
  }

  @override
  Future<void> write(String value) async {
    try {
      await primary.write(value).timeout(const Duration(seconds: 3));
      unawaited(fallback.write(value));
      return;
    } catch (_) {}

    try {
      await fallback.write(value).timeout(const Duration(seconds: 3));
    } catch (_) {
      rethrow;
    }
  }
}
