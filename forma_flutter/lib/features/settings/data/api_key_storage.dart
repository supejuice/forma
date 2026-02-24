import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
