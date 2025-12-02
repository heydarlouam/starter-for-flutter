import 'package:appwrite/appwrite.dart';

/// دسته‌بندی کلی خطاهای شبکه
enum NetworkErrorType {
  network,       // مشکلات ارتباط (SocketException و ...)
  server,        // 5xx
  unauthorized,  // 401
  forbidden,     // 403
  notFound,      // 404
  timeout,       // TimeoutException
  validation,    // 4xx مربوط به ورودی‌های غلط / ولیدیشن
  cancelled,     // درخواست لغو شده
  serialization, // خطای parse / mapping
  unknown,       // هر چیز پیش‌بینی‌نشده
}

/// مدل واحد خطای شبکه در کل لایه‌ی دیتا
class NetworkError {
  final NetworkErrorType type;

  /// پیام کاربرپسند برای نمایش در UI
  final String userMessage;

  /// پیام فنی‌تر برای لاگ و دیباگ
  final String devMessage;

  final int? statusCode;
  final String? code;
  final Object? originalException;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? details;

  const NetworkError({
    required this.type,
    required this.userMessage,
    required this.devMessage,
    this.statusCode,
    this.code,
    this.originalException,
    this.stackTrace,
    this.details,
  });

  /// برای حفظ سازگاری با کدهای قبلی که از `error.message` استفاده می‌کردند
  String get message => userMessage;

  // --------- factory های راحت برای انواع خطا ---------

  factory NetworkError.network({
    String message = 'خطا در اتصال به شبکه',
    Object? exception,
    StackTrace? stackTrace,
  }) {
    return NetworkError(
      type: NetworkErrorType.network,
      userMessage: message,
      devMessage: exception?.toString() ?? message,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.timeout({
    String message = 'مهلت درخواست به پایان رسید',
    Object? exception,
    StackTrace? stackTrace,
  }) {
    return NetworkError(
      type: NetworkErrorType.timeout,
      userMessage: message,
      devMessage: exception?.toString() ?? message,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.server({
    String message = 'خطای داخلی سرور',
    int? statusCode,
    String? code,
    Object? exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) {
    final devMsg =
        'Server error (statusCode=$statusCode, code=$code, message=$message, details=$details)';
    return NetworkError(
      type: NetworkErrorType.server,
      userMessage: message,
      devMessage: devMsg,
      statusCode: statusCode,
      code: code,
      originalException: exception,
      stackTrace: stackTrace,
      details: details,
    );
  }

  factory NetworkError.unauthorized({
    String message = 'دسترسی غیرمجاز. لطفاً دوباره وارد شوید.',
    int? statusCode,
    String? code,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final devMsg =
        'Unauthorized (statusCode=$statusCode, code=$code, message=$message)';
    return NetworkError(
      type: NetworkErrorType.unauthorized,
      userMessage: message,
      devMessage: devMsg,
      statusCode: statusCode,
      code: code,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.forbidden({
    String message = 'شما اجازه انجام این عملیات را ندارید',
    int? statusCode,
    String? code,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final devMsg =
        'Forbidden (statusCode=$statusCode, code=$code, message=$message)';
    return NetworkError(
      type: NetworkErrorType.forbidden,
      userMessage: message,
      devMessage: devMsg,
      statusCode: statusCode,
      code: code,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.notFound({
    String message = 'مورد مورد نظر یافت نشد',
    int? statusCode,
    String? code,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final devMsg =
        'NotFound (statusCode=$statusCode, code=$code, message=$message)';
    return NetworkError(
      type: NetworkErrorType.notFound,
      userMessage: message,
      devMessage: devMsg,
      statusCode: statusCode,
      code: code,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.validation({
    String message = 'داده‌های ارسال‌شده معتبر نیستند',
    int? statusCode,
    String? code,
    Object? exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) {
    final devMsg =
        'Validation error (statusCode=$statusCode, code=$code, message=$message, details=$details)';
    return NetworkError(
      type: NetworkErrorType.validation,
      userMessage: message,
      devMessage: devMsg,
      statusCode: statusCode,
      code: code,
      originalException: exception,
      stackTrace: stackTrace,
      details: details,
    );
  }

  factory NetworkError.cancelled({
    String message = 'درخواست لغو شد',
    Object? exception,
    StackTrace? stackTrace,
  }) {
    return NetworkError(
      type: NetworkErrorType.cancelled,
      userMessage: message,
      devMessage: exception?.toString() ?? message,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.serialization({
    String message = 'خطا در پردازش داده‌ها',
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final devMsg = 'Serialization error: ${exception ?? message}';
    return NetworkError(
      type: NetworkErrorType.serialization,
      userMessage: message,
      devMessage: devMsg,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.unknown({
    String message = 'خطای ناشناخته رخ داد',
    Object? exception,
    StackTrace? stackTrace,
  }) {
    final devMsg = 'Unknown error: ${exception ?? message}';
    return NetworkError(
      type: NetworkErrorType.unknown,
      userMessage: message,
      devMessage: devMsg,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  /// مپ کردن AppwriteException به NetworkError
  factory NetworkError.fromAppwriteException(
      AppwriteException exception, [
        StackTrace? stackTrace,
      ]) {
    final int? statusCode = exception.code;
    final String? code = exception.type;
    final String rawMessage = exception.message ?? '';

    // پیام کاربر
    final String userMessage =
    rawMessage.isEmpty ? 'خطای نامشخص از سمت سرور' : rawMessage;

    // پیام فنی برای لاگ
    final String devMessage =
        'AppwriteException(statusCode=$statusCode, type=$code, message=$rawMessage, response=${exception.response})';

    Map<String, dynamic>? details;
    final resp = exception.response;
    if (resp is Map<String, dynamic>) {
      details = resp;
    }

    if (statusCode == 401) {
      return NetworkError(
        type: NetworkErrorType.unauthorized,
        userMessage: 'دسترسی شما منقضی شده است. لطفاً دوباره وارد شوید.',
        devMessage: devMessage,
        statusCode: statusCode,
        code: code,
        originalException: exception,
        stackTrace: stackTrace,
        details: details,
      );
    }

    if (statusCode == 403) {
      return NetworkError(
        type: NetworkErrorType.forbidden,
        userMessage: 'شما اجازه انجام این عملیات را ندارید.',
        devMessage: devMessage,
        statusCode: statusCode,
        code: code,
        originalException: exception,
        stackTrace: stackTrace,
        details: details,
      );
    }

    if (statusCode == 404) {
      return NetworkError(
        type: NetworkErrorType.notFound,
        userMessage: 'مورد مورد نظر یافت نشد.',
        devMessage: devMessage,
        statusCode: statusCode,
        code: code,
        originalException: exception,
        stackTrace: stackTrace,
        details: details,
      );
    }

    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return NetworkError(
        type: NetworkErrorType.validation,
        userMessage: userMessage,
        devMessage: devMessage,
        statusCode: statusCode,
        code: code,
        originalException: exception,
        stackTrace: stackTrace,
        details: details,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return NetworkError(
        type: NetworkErrorType.server,
        userMessage: userMessage,
        devMessage: devMessage,
        statusCode: statusCode,
        code: code,
        originalException: exception,
        stackTrace: stackTrace,
        details: details,
      );
    }

    return NetworkError(
      type: NetworkErrorType.unknown,
      userMessage: userMessage,
      devMessage: devMessage,
      statusCode: statusCode,
      code: code,
      originalException: exception,
      stackTrace: stackTrace,
      details: details,
    );
  }

  @override
  String toString() {
    return 'NetworkError(type: $type, userMessage: $userMessage, statusCode: $statusCode, code: $code)';
  }
}
