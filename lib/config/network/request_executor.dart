import 'dart:async';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'api_result.dart';
import 'network_error.dart';
/// اینترفیس ساده برای لاگ کردن رویدادهای شبکه
abstract class NetworkLogger {
  void log(String message);
  void logError(String message, NetworkError error);
}

/// پیاده‌سازی ساده که روی console لاگ می‌کند (در صورت نیاز)
class ConsoleNetworkLogger implements NetworkLogger {
  final bool enabled;

  const ConsoleNetworkLogger({this.enabled = true});

  @override
  void log(String message) {
    if (!enabled) return;
    // می‌توانی بعدها این را با debugPrint یا Logger دیگر جایگزین کنی
    // ignore: avoid_print
    print('[NETWORK] $message');
  }

  @override
  void logError(String message, NetworkError error) {
    if (!enabled) return;
    // ignore: avoid_print
    print('[NETWORK][ERROR] $message -> ${error.devMessage}');
  }
}

/// این کلاس تمام try/catch, timeout, و تبدیل exception به NetworkError را متمرکز می‌کند.
class RequestExecutor {
  final NetworkLogger? logger;

  const RequestExecutor({this.logger});

  /// اجرای امن یک کال async که از شبکه استفاده می‌کند.
  ///
  /// [action] همان call اصلی است (مثلا listDocuments, createDocument و ...).
  /// [label] برای logging (اختیاری)؛ در صورت نیاز برای تشخیص راحت‌تر requestها.
  /// [mapErrorMessage] اگر بخواهی برای یک کال خاص، پیام کاربرپسند سفارشی بدهی.
  Future<ApiResult<T>> execute<T>(
      Future<T> Function() action, {
        Duration? timeout,
        String? label,
        String Function(NetworkError error)? mapErrorMessage,
      }) async {
    final String requestLabel = label ?? 'Request<$T>';

    logger?.log('$requestLabel: started');

    try {
      final Future<T> future =
      timeout != null ? action().timeout(timeout) : action();

      final T result = await future;

      logger?.log('$requestLabel: success');

      return ApiResult.success(result);
    } on TimeoutException catch (e, st) {
      var error = NetworkError.timeout(
        exception: e,
        stackTrace: st,
      );
      error = _maybeMapMessage(error, mapErrorMessage);

      logger?.logError('$requestLabel: timeout', error);

      return ApiResult.failure(error);
    } on SocketException catch (e, st) {
      var error = NetworkError.network(
        exception: e,
        stackTrace: st,
      );
      error = _maybeMapMessage(error, mapErrorMessage);

      logger?.logError('$requestLabel: network error (socket)', error);

      return ApiResult.failure(error);
    } on AppwriteException catch (e, st) {
      var error = NetworkError.fromAppwriteException(e, st);
      error = _maybeMapMessage(error, mapErrorMessage);

      logger?.logError('$requestLabel: appwrite error', error);

      return ApiResult.failure(error);
    } on Exception catch (e, st) {
      var error = NetworkError.unknown(
        exception: e,
        stackTrace: st,
      );
      error = _maybeMapMessage(error, mapErrorMessage);

      logger?.logError('$requestLabel: exception', error);

      return ApiResult.failure(error);
    } catch (e, st) {
      var error = NetworkError.unknown(
        exception: e,
        stackTrace: st,
      );
      error = _maybeMapMessage(error, mapErrorMessage);

      logger?.logError('$requestLabel: non-Exception error', error);

      return ApiResult.failure(error);
    }
  }

  NetworkError _maybeMapMessage(
      NetworkError error,
      String Function(NetworkError error)? mapper,
      ) {
    if (mapper == null) {
      return error;
    }

    final mappedUserMessage = mapper(error);

    return NetworkError(
      type: error.type,
      userMessage: mappedUserMessage,
      devMessage: error.devMessage,
      statusCode: error.statusCode,
      code: error.code,
      originalException: error.originalException,
      stackTrace: error.stackTrace,
      details: error.details,
    );
  }
}
