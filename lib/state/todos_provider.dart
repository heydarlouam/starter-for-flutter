import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import 'package:appwrite_flutter_starter_kit/config/environment.dart';
import 'package:appwrite_flutter_starter_kit/config/network/api_result.dart';
import 'package:appwrite_flutter_starter_kit/config/network/realtime_manager.dart';
import 'package:appwrite_flutter_starter_kit/data/models/todo.dart';
import 'package:appwrite_flutter_starter_kit/data/repository/todos_repository.dart';
import 'package:appwrite_flutter_starter_kit/state/base_provider.dart';

/// Provider برای مدیریت لیست Todoها (Paging + Realtime + CRUD خوش‌بینانه)
class TodosProvider extends BaseProvider {
  final TodosRepository _repository;

  static const int _pageSize = 15;

  /// لیست اصلی Todoها
  List<Todo> todos = [];

  /// وضعیت‌های لودینگ / صفحه‌بندی
  bool loading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  String? _cursorAfter;
  final Set<String> _loadedIds = {};

  /// پیام خطا برای نمایش در UI
  String? error;

  StreamSubscription<RealtimeEvent<Todo>>? _realtimeSub;

  TodosProvider({TodosRepository? repository})
      : _repository = repository ?? TodosRepository() {
    _init();
  }

  Future<void> _init() async {
    await _loadInitialTodos();
    _subscribeToRealtime();
  }

  /// لود اولیه‌ی لیست Todoها
  Future<void> _loadInitialTodos() async {
    loading = true;
    isLoadingMore = false;
    hasMore = true;
    error = null;
    _cursorAfter = null;
    _loadedIds.clear();
    todos = [];
    notifyListeners();

    final result = await _repository.getAll(
      queries: [
        // جدیدترین تغییرات بالا
        Query.orderDesc(r'$updatedAt'),
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
      todos.add(item);
      _loadedIds.add(item.id);
    }

    _sortTodos();

    loading = false;
    hasMore = items.length >= _pageSize;
    _cursorAfter = hasMore ? items.last.id : null;

    notifyListeners();
  }

  /// برای Pull-to-Refresh
  Future<void> refresh() async {
    await _loadInitialTodos();
  }

  /// لود صفحه‌ی بعدی (Infinite Scroll)
  Future<void> loadMore() async {
    if (loading || isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    error = null;
    notifyListeners();

    final queries = <String>[
      Query.orderDesc(r'$updatedAt'),
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

    for (final item in items) {
      final idx = todos.indexWhere((t) => t.id == item.id);
      if (idx == -1) {
        todos.add(item);
        _loadedIds.add(item.id);
      } else {
        todos[idx] = item;
      }
    }

    _sortTodos();

    hasMore = items.length >= _pageSize;
    _cursorAfter = hasMore ? items.last.id : null;

    isLoadingMore = false;
    notifyListeners();
  }

  /// مقایسه‌ی Priority برای مرتب‌سازی
  ///
  /// high > medium > low > null/unknown
  int _comparePriority(String? a, String? b) {
    int score(String? v) {
      switch (v) {
        case 'high':
          return 3;
        case 'medium':
          return 2;
        case 'low':
          return 1;
        default:
          return 0;
      }
    }

    final sa = score(a);
    final sb = score(b);
    return sb.compareTo(sa); // نزولی: high (3) بالاتر از low (1)
  }

  /// مرتب‌سازی:
  /// - اول todoهای انجام نشده
  /// - بین undoneها: نزدیک‌ترین due_date، بعد priority، بعد زمان آخرین تغییر
  /// - بین doneها: آخرین completedAt/updatedAt جدیدتر بالاتر
  void _sortTodos() {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);

    todos.sort((a, b) {
      // undone اول، done بعد
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }

      // هر دو undone → بر اساس due_date و priority
      if (!a.isDone && !b.isDone) {
        final aDue = a.dueDate;
        final bDue = b.dueDate;

        if (aDue != null && bDue != null) {
          final cmp = aDue.compareTo(bDue); // زودتر اول
          if (cmp != 0) return cmp;
        } else if (aDue != null) {
          // a تاریخ دارد، b ندارد → a بالاتر
          return -1;
        } else if (bDue != null) {
          // b تاریخ دارد، a ندارد → b بالاتر
          return 1;
        }

        // اگر due_date برابر بود یا هر دو null → priority
        final prioCmp = _comparePriority(a.priority, b.priority);
        if (prioCmp != 0) return prioCmp;
      }

      // در نهایت بر اساس زمان آخرین تغییر
      final aTime =
          a.updatedAt ?? a.completedAt ?? a.createdAt ?? epoch;
      final bTime =
          b.updatedAt ?? b.completedAt ?? b.createdAt ?? epoch;
      return bTime.compareTo(aTime); // جدیدتر بالاتر
    });
  }

  /// اشتراک روی Realtime برای کالکشن todos
  void _subscribeToRealtime() {
    _realtimeSub?.cancel();

    final stream = RealtimeManager.instance.subscribeCollection<Todo>(
      databaseId: Environment.databaseId,
      collectionId: Environment.collectionIdTodos,
      fromJson: Todo.fromJson,
    );

    _realtimeSub = stream.listen(
          (event) {
        final rowId = event.documentId;
        final data = event.data;

        // delete
        if (event.action == RealtimeAction.delete) {
          if (rowId != null) {
            todos.removeWhere((t) => t.id == rowId);
            _loadedIds.remove(rowId);
            _sortTodos();
            notifyListeners();
          }
          return;
        }

        if (data == null) {
          return;
        }

        switch (event.action) {
          case RealtimeAction.create:
            {
              final existingIndex =
              todos.indexWhere((t) => t.id == data.id);
              if (existingIndex == -1) {
                todos.insert(0, data);
                _loadedIds.add(data.id);
              } else {
                todos[existingIndex] = data;
              }
              break;
            }
          case RealtimeAction.update:
            {
              final index = todos.indexWhere((t) => t.id == data.id);
              if (index != -1) {
                todos[index] = data;
              } else {
                todos.insert(0, data);
                _loadedIds.add(data.id);
              }
              break;
            }
          case RealtimeAction.unknown:
            {
              if (kDebugMode) {
                debugPrint('Unknown todo realtime action: ${event.raw}');
              }
              break;
            }
          case RealtimeAction.delete:
          // بالاتر هندل شده
            break;
        }

        _sortTodos();
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('Realtime error (todos): $e');
        }
      },
    );
  }

  // ----------------- CRUD -----------------

  /// ایجاد Todo جدید
  Future<ApiResult<Todo>> create({
    required String title,
    String? description,
    DateTime? dueDate,
    String? priority,
  }) async {
    final newTodo = Todo(
      id: '',
      title: title,
      isDone: false,
      description: description,
      dueDate: dueDate,
      priority: priority,
      completedAt: null,
      createdAt: null,
      updatedAt: null,
    );

    final result = await _repository.create(newTodo);

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    final created = result.requireData;
    final index = todos.indexWhere((t) => t.id == created.id);
    if (index == -1) {
      todos.insert(0, created);
      _loadedIds.add(created.id);
    } else {
      todos[index] = created;
    }
    _sortTodos();
    notifyListeners();

    return result;
  }

  /// ویرایش جزئیات (title, description, dueDate, priority)
  Future<ApiResult<Todo>> updateDetails(
      Todo todo, {
        required String title,
        String? description,
        DateTime? dueDate,
        String? priority,
      }) async {
    final updated = todo.copyWith(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );

    final result = await _repository.update(todo.id, updated);

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    final updatedRow = result.requireData;
    final index = todos.indexWhere((t) => t.id == updatedRow.id);
    if (index != -1) {
      todos[index] = updatedRow;
    } else {
      todos.insert(0, updatedRow);
      _loadedIds.add(updatedRow.id);
    }
    _sortTodos();
    notifyListeners();

    return result;
  }

  /// تغییر وضعیت انجام شدن (تیک خوردن / برداشتن تیک)
  Future<ApiResult<Todo>> toggleDone(Todo todo) async {
    final bool nextIsDone = !todo.isDone;

    DateTime? nextCompletedAt = todo.completedAt;
    if (!todo.isDone && nextIsDone) {
      // false -> true
      nextCompletedAt = DateTime.now();
    } else if (todo.isDone && !nextIsDone) {
      // true -> false
      nextCompletedAt = null;
    }

    final updated = todo.copyWith(
      isDone: nextIsDone,
      completedAt: nextCompletedAt,
    );

    final result = await _repository.update(todo.id, updated);

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    final updatedRow = result.requireData;
    final index = todos.indexWhere((t) => t.id == updatedRow.id);
    if (index != -1) {
      todos[index] = updatedRow;
    } else {
      todos.insert(0, updatedRow);
      _loadedIds.add(updatedRow.id);
    }
    _sortTodos();
    notifyListeners();

    return result;
  }

  /// حذف Todo
  Future<ApiResult<void>> deleteTodo(Todo todo) async {
    final result = await _repository.delete(todo.id);

    if (result.isFailure) {
      return ApiResult.failure(result.requireError);
    }

    todos.removeWhere((t) => t.id == todo.id);
    _loadedIds.remove(todo.id);
    _sortTodos();
    notifyListeners();

    return result;
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}
