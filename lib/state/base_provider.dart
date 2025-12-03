import 'package:flutter/foundation.dart';

/// BaseProvider:
/// - جلوگیری از notifyListeners بعد از dispose
/// - پایه‌ای برای همه‌ی ChangeNotifierهای پروژه
abstract class BaseProvider extends ChangeNotifier {
  bool _disposed = false;

  /// اگر جایی نیاز داشتی بدانی Provider هنوز زنده است یا نه
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    // اگر dispose شده، دیگر UI را آپدیت نکن
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
