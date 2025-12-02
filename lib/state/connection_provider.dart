import 'package:flutter/foundation.dart';

import 'package:appwrite/appwrite.dart';

import 'package:appwrite_flutter_starter_kit/config/environment.dart';
import 'package:appwrite_flutter_starter_kit/config/network/appwrite_client.dart';
import 'package:appwrite_flutter_starter_kit/config/network/api_result.dart';
import 'package:appwrite_flutter_starter_kit/config/network/network_error.dart';
import 'package:appwrite_flutter_starter_kit/config/network/request_executor.dart';

/// Provider برای تست اتصال به Appwrite (ping)
class ConnectionProvider extends ChangeNotifier {
  final RequestExecutor _executor;

  bool isPinging = false;
  bool? lastSuccess; // null = هنوز پینگی انجام نشده
  String? lastMessage;
  DateTime? lastPingAt;

  final List<String> logs = [];

  ConnectionProvider({RequestExecutor? executor})
      : _executor = executor ?? const RequestExecutor();

  Future<void> sendPing() async {
    // اگر در حال پینگ هستیم، دوباره شروع نکن
    if (isPinging) return;

    isPinging = true;
    _addLog('Ping started...');
    notifyListeners();

    final Databases databases = AppwriteClient.instance.databases;

    final ApiResult<void> result = await _executor.execute<void>(() async {
      // یک درخواست خیلی سبک: گرفتن ۱ داکیومنت (یا صفر).
      await databases.listDocuments(
        databaseId: Environment.databaseId,
        collectionId: Environment.collectionIdTestStrings,
        queries: [
          Query.limit(1),
        ],
      );
      return;
    });

    isPinging = false;
    lastPingAt = DateTime.now();

    if (result.isSuccess) {
      lastSuccess = true;
      lastMessage = 'Ping success (${lastPingAt!.toIso8601String()})';
      _addLog('Ping success ✅');
    } else {
      lastSuccess = false;
      final NetworkError error = result.requireError;
      lastMessage = 'Ping failed: ${error.message}';
      _addLog('Ping failed ❌ - ${error.message}');
    }

    notifyListeners();
  }

  void clearLogs() {
    logs.clear();
    notifyListeners();
  }

  void _addLog(String msg) {
    final now = DateTime.now().toIso8601String();
    logs.insert(0, '[$now] $msg');
    if (kDebugMode) {
      // برای دیباگ
      // ignore: avoid_print
      print(logs.first);
    }
  }
}
