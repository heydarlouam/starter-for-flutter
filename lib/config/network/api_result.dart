import 'network_error.dart';

class ApiResult<T> {
  final T? data;
  final NetworkError? error;

  const ApiResult._({
    this.data,
    this.error,
  });

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  T get requireData {
    if (data == null) {
      throw StateError(
        'ApiResult has no data. Check isSuccess and data != null before using requireData.',
      );
    }
    return data as T;
  }

  NetworkError get requireError {
    if (error == null) {
      throw StateError(
        'ApiResult has no error. Check isFailure and error != null before using requireError.',
      );
    }
    return error!;
  }

  factory ApiResult.success(T data) {
    return ApiResult._(data: data);
  }

  /// برای عملیات‌هایی مثل delete که دیتا ندارند.
  factory ApiResult.successNoData() {
    return const ApiResult._();
  }

  factory ApiResult.failure(NetworkError error) {
    return ApiResult._(error: error);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResult.success($data)';
    }
    return 'ApiResult.failure($error)';
  }
}
