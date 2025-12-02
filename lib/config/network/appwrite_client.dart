import 'package:appwrite/appwrite.dart';

/// Singleton برای نگه‌داری Client / Databases / Realtime در کل اپ.
class AppwriteClient {
  AppwriteClient._internal();

  static final AppwriteClient instance = AppwriteClient._internal();

  Client? _client;
  Databases? _databases;
  Realtime? _realtime;

  late final Functions functions; // ✅ اضافه شد

  bool get isInitialized => _client != null;

  Future<void> init({
    required String endpoint,
    required String projectId,
    bool selfSigned = true,
  }) async {
    if (isInitialized) return;

    final client = Client()
      ..setEndpoint(endpoint)
      ..setProject(projectId);

    if (selfSigned) {
      client.setSelfSigned(status: true); // مثل قبل Provider قدیمی‌ات
    }

    _client = client;
    _databases = Databases(client);
    _realtime = Realtime(client);
  }

  Client get client {
    final c = _client;
    if (c == null) {
      throw StateError(
        'AppwriteClient هنوز init نشده. قبل از استفاده، init را صدا بزن.',
      );
    }
    return c;
  }

  Databases get databases {
    final d = _databases;
    if (d == null) {
      throw StateError(
        'AppwriteClient هنوز init نشده. قبل از استفاده، init را صدا بزن.',
      );
    }
    return d;
  }

  Realtime get realtime {
    final r = _realtime;
    if (r == null) {
      throw StateError(
        'AppwriteClient هنوز init نشده. قبل از استفاده، init را صدا بزن.',
      );
    }
    return r;
  }

  void setJWT(String jwt) {
    client.setJWT(jwt);
  }

  void setSession(String sessionId) {
    client.setSession(sessionId);
  }

  void reset() {
    _client = null;
    _databases = null;
    _realtime = null;
  }
}
