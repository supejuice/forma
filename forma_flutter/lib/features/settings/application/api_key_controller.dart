import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_key_storage.dart';

final Provider<ApiKeyStorage> apiKeyStorageProvider = Provider<ApiKeyStorage>(
  (Ref ref) => SecureApiKeyStorage(const FlutterSecureStorage()),
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
    await ref.read(apiKeyStorageProvider).clear();
    state = const AsyncValue<String?>.data(null);
  }

  Future<void> save(String key) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await ref.read(apiKeyStorageProvider).write(trimmed);
    state = AsyncValue<String?>.data(trimmed);
  }

  Future<void> reload() async {
    state = const AsyncValue<String?>.loading();
    state = await AsyncValue.guard<String?>(
      () => ref.read(apiKeyStorageProvider).read(),
    );
  }
}
