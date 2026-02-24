import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_key_storage.dart';

final Provider<ApiKeyStorage> apiKeyStorageProvider = Provider<ApiKeyStorage>(
  (Ref ref) => ResilientApiKeyStorage(
    primary: SecureApiKeyStorage(const FlutterSecureStorage()),
    fallback: SharedPrefsApiKeyStorage(),
  ),
);

final AsyncNotifierProvider<ApiKeyController, String?>
apiKeyControllerProvider = AsyncNotifierProvider<ApiKeyController, String?>(
  ApiKeyController.new,
);

class ApiKeyController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return ref.read(apiKeyStorageProvider).read();
  }

  Future<void> clear() async {
    state = const AsyncValue<String?>.data(null);
    try {
      await ref
          .read(apiKeyStorageProvider)
          .clear()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // State is already cleared for current session.
    }
  }

  Future<void> save(String key) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = AsyncValue<String?>.data(trimmed);
    try {
      await ref
          .read(apiKeyStorageProvider)
          .write(trimmed)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Key remains available in-memory for current app session.
    }
  }

  Future<void> reload() async {
    state = const AsyncValue<String?>.loading();
    state = await AsyncValue.guard<String?>(
      () => ref.read(apiKeyStorageProvider).read(),
    );
  }
}
