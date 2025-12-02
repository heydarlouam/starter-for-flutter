import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_flutter_starter_kit/config/environment.dart';
import 'package:appwrite_flutter_starter_kit/config/network/api_result.dart';
import 'package:appwrite_flutter_starter_kit/config/network/realtime_manager.dart';
import 'package:appwrite_flutter_starter_kit/data/models/test_string.dart';
import 'package:appwrite_flutter_starter_kit/data/repository/test_strings_repository.dart';
import 'package:flutter/foundation.dart';

class TestStringsProvider extends ChangeNotifier {
  final TestStringsRepository _repository;

  // اندازه هر صفحه (۵۰ تا ۵۰ تا)
  static const int _pageSize = 15;

  // State اصلی
  List<TestString> rows = [];
  bool loading = true;        // لود اولیه صفحه
  bool isLoadingMore = false; // لود صفحه‌های بعدی
  bool hasMore = true;        // آیا هنوز دیتا برای صفحات بعدی هست یا نه

  String? _cursorAfter;               // برای pagination با cursor
  final Set<String> _loadedIds = {};  // IDهایی که تا الان گرفتیم (برای حذف تکراری‌ها)

  String? error;

  StreamSubscription<RealtimeEvent<TestString>>? _realtimeSub;

  TestStringsProvider({TestStringsRepository? repository})
      : _repository = repository ?? TestStringsRepository() {
    _init();
  }

  Future<void> _init() async {
    await _loadInitialRows();
    _subscribeToRealtime();
  }

  /// لود اولیه (صفحه اول) با مرتب‌سازی بر اساس $updatedAt
  Future<void> _loadInitialRows() async {
    loading = true;
    isLoadingMore = false;
    hasMore = true;
    error = null;
    _cursorAfter = null;
    _loadedIds.clear();
    rows = [];
    notifyListeners();

    final result = await _repository.getAll(
      queries: [
        Query.orderDesc('\$updatedAt'), // جدیدترین آپدیت‌ها بالا
        Query.limit(_pageSize),
      ],
    );

    if (result.isFailure) {
      loading = false;
      error = result.requireError.message;
      notifyListeners();
      return;
    }

    final items = result.requireData;

    for (final item in items) {
      rows.add(item);
      _loadedIds.add(item.id);
    }

    _sortRowsByUpdatedAt();

    loading = false;
    hasMore = items.length >= _pageSize;
    _cursorAfter = hasMore ? items.last.id : null;

    notifyListeners();
  }

  /// برای pull-to-refresh اگر بعداً خواستی
  Future<void> refresh() async {
    await _loadInitialRows();
  }

  /// لود صفحه‌ی بعدی با cursor (۵۰ تا ۵۰ تا)
  Future<void> loadMore() async {
    if (loading || isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    error = null;
    notifyListeners();

    final queries = <String>[
      Query.orderDesc('\$updatedAt'),
      Query.limit(_pageSize),
    ];

    if (_cursorAfter != null) {
      queries.add(Query.cursorAfter(_cursorAfter!));
    }

    final result = await _repository.getAll(queries: queries);

    if (result.isFailure) {
      isLoadingMore = false;
      error = result.requireError.message;
      notifyListeners();
      return;
    }

    final items = result.requireData;

    if (items.isEmpty) {
      hasMore = false;
      isLoadingMore = false;
      notifyListeners();
      return;
    }

    // جلوگیری از تکرار + به‌روز کردن رکوردهای قبلی
    for (final item in items) {
      final idx = rows.indexWhere((row) => row.id == item.id);
      if (idx == -1) {
        rows.add(item);
        _loadedIds.add(item.id);
      } else {
        rows[idx] = item;
      }
    }

    _sortRowsByUpdatedAt();

    hasMore = items.length >= _pageSize;
    _cursorAfter = hasMore ? items.last.id : null;

    isLoadingMore = false;
    notifyListeners();
  }

  /// مرتب‌سازی لیست بر اساس updatedAt (اگر نبود، از createdAt استفاده می‌کنیم)
  void _sortRowsByUpdatedAt() {
    rows.sort((a, b) {
      final aTime =
          a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime); // جدیدترین اول
    });
  }

  /// اشتراک روی Realtime برای همین کالکشن
  void _subscribeToRealtime() {
    _realtimeSub?.cancel();

    final stream = RealtimeManager.instance.subscribeCollection<TestString>(
      databaseId: Environment.databaseId,
      collectionId: Environment.collectionIdTestStrings,
      fromJson: TestString.fromJson,
    );

    _realtimeSub = stream.listen(
          (event) {
        final rowId = event.documentId;
        final data = event.data;

        // حذف
        if (event.action == RealtimeAction.delete) {
          if (rowId != null) {
            rows.removeWhere((row) => row.id == rowId);
            _loadedIds.remove(rowId);
            _sortRowsByUpdatedAt();
            notifyListeners();
          }
          return;
        }

        // create / update بدون دیتا، بی‌معنی است
        if (data == null) {
          return;
        }

        switch (event.action) {
          case RealtimeAction.create:
            {
              final existingIndex =
              rows.indexWhere((row) => row.id == data.id);
              if (existingIndex == -1) {
                // رکورد جدید → بگذار بالا
                rows.insert(0, data);
                _loadedIds.add(data.id);
              } else {
                // اگر به هر دلیل قبلاً بوده، آپدیت کن
                rows[existingIndex] = data;
              }
              break;
            }
          case RealtimeAction.update:
            {
              final index = rows.indexWhere((row) => row.id == data.id);
              if (index != -1) {
                rows[index] = data;
              } else {
                // اگر در صفحه‌های قبلی بوده ولی لود نشده، و الان آپدیت شده → بیار بالا
                rows.insert(0, data);
                _loadedIds.add(data.id);
              }
              break;
            }
          case RealtimeAction.unknown:
            {
              if (kDebugMode) {
                debugPrint('Unknown realtime action: ${event.raw}');
              }
              break;
            }
          case RealtimeAction.delete:
          // بالاتر هندل شده
            break;
        }

        _sortRowsByUpdatedAt();
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('Realtime error: $e');
        }
      },
    );
  }

  // ----------------- CRUD برای UI (بدون دیالوگ) -----------------

  /// ایجاد رکورد جدید
  Future<ApiResult<TestString>> create(String text) async {
    final newRow = TestString(id: '', text: text);

    final result = await _repository.create(newRow);

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    // لیست با Realtime به‌روزرسانی می‌شود.
    return result;
  }

  /// ویرایش رکورد
  Future<ApiResult<TestString>> update(TestString row, String newText) async {
    final updated = row.copyWith(text: newText);
    final result = await _repository.update(row.id, updated);

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    // لیست با Realtime به‌روزرسانی می‌شود.
    return result;
  }

  /// حذف رکورد
  Future<ApiResult<void>> delete(TestString row) async {
    final result = await _repository.delete(row.id);

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    // حذف از لیست با Realtime انجام می‌شود.
    return result;
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}
