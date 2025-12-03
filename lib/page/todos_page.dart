import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appwrite_flutter_starter_kit/data/models/todo.dart';
import 'package:appwrite_flutter_starter_kit/state/todos_provider.dart';
import 'package:appwrite_flutter_starter_kit/utils/app_notifier.dart';

import 'package:getwidget/getwidget.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class TodosPage extends StatelessWidget {
  static const String routeName = '/todos';

  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todos (Realtime + Provider + Network Layer)',
        ),
      ),
      floatingActionButton: GFFloatingWidget(
        child: FloatingActionButton(
          onPressed: () => _showAddEditDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (provider.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GFColors.DANGER.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: GFColors.DANGER),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: GFColors.DANGER),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: provider.loading && provider.todos.isEmpty
                  ? _buildShimmerList(context)
                  : provider.todos.isEmpty
                  ? const Center(child: Text('No todos yet'))
                  : NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (provider.hasMore &&
                      !provider.isLoadingMore &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent -
                              200) {
                    provider.loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: _calculateItemCount(provider),
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index >= provider.todos.length) {
                      if (provider.isLoadingMore) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          child: _buildShimmerCard(context),
                        );
                      }

                      if (!provider.hasMore &&
                          provider.todos.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          child: _buildEndOfListCard(context),
                        );
                      }
                    }

                    final todo = provider.todos[index];

                    return GFCard(
                      padding: const EdgeInsets.all(0),
                      margin: EdgeInsets.zero,
                      content: GFListTile(
                        title: Row(
                          children: [
                            Checkbox(
                              value: todo.isDone,
                              onChanged: (_) =>
                                  provider.toggleDone(todo),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                todo.title.isEmpty
                                    ? '(no title)'
                                    : todo.title,
                                style: TextStyle(
                                  decoration: todo.isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subTitle: _buildSubtitle(context, todo),
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GFIconButton(
                              icon: const Icon(Icons.edit),
                              type: GFButtonType.transparent,
                              onPressed: () => _showAddEditDialog(
                                context,
                                todo: todo,
                              ),
                            ),
                            GFIconButton(
                              icon: const Icon(Icons.delete),
                              color: GFColors.DANGER,
                              type: GFButtonType.transparent,
                              onPressed: () =>
                                  _showDeleteDialog(context, todo),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Subtitle (description + due_date + priority + meta) -----------------

  Widget _buildSubtitle(BuildContext context, Todo todo) {
    final List<Widget> children = [];

    // توضیحات
    if ((todo.description ?? '').trim().isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            todo.description!,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    // ردیف due_date + priority
    final List<Widget> metaRow = [];

    if (todo.dueDate != null) {
      final bool overdue = _isOverdue(todo);
      metaRow.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event,
              size: 16,
              color: overdue ? GFColors.DANGER : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              overdue
                  ? 'سررسید: ${_formatDate(todo.dueDate)} (گذشته)'
                  : 'سررسید: ${_formatDate(todo.dueDate)}',
              style: TextStyle(
                fontSize: 12,
                color: overdue ? GFColors.DANGER : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final String? prLabel = _priorityLabel(todo.priority);
    if (prLabel != null) {
      metaRow.add(
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _priorityColor(todo.priority).withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _priorityColor(todo.priority).withOpacity(0.4),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag,
                size: 14,
                color: _priorityColor(todo.priority),
              ),
              const SizedBox(width: 4),
              Text(
                prLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: _priorityColor(todo.priority),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (metaRow.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: metaRow,
          ),
        ),
      );
    }

    // ID و زمان تکمیل (برای done ها)
    final List<Widget> idRow = [];

    idRow.add(
      Text(
        'ID: ${todo.id}',
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black45,
        ),
      ),
    );

    if (todo.isDone && todo.completedAt != null) {
      idRow.add(const SizedBox(width: 12));
      idRow.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 14,
              color: GFColors.SUCCESS,
            ),
            const SizedBox(width: 4),
            Text(
              'تکمیل: ${_formatDateTime(todo.completedAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: idRow,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  bool _isOverdue(Todo todo) {
    if (todo.isDone || todo.dueDate == null) return false;
    final now = DateTime.now();
    // فقط تاریخ را مقایسه می‌کنیم، نه زمان
    final due = todo.dueDate!;
    final DateTime dueDateOnly = DateTime(due.year, due.month, due.day);
    final DateTime nowDateOnly = DateTime(now.year, now.month, now.day);
    return dueDateOnly.isBefore(nowDateOnly);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String? _priorityLabel(String? priority) {
    switch (priority) {
      case 'high':
        return 'اولویت بالا';
      case 'medium':
        return 'اولویت متوسط';
      case 'low':
        return 'اولویت پایین';
      default:
        return null;
    }
  }


  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return GFColors.DANGER;
      case 'medium':
        return GFColors.WARNING;
      case 'low':
        return GFColors.SUCCESS;
      default:
        return Colors.grey;
    }
  }

  // ----------------- SHIMMER: لیست اسکلت کارت‌ها برای لود اولیه -----------------

  Widget _buildShimmerList(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildShimmerCard(context),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Shimmer(
      child: GFCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.zero,
        content: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- دیالوگ افزودن / ویرایش -----------------

  void _showAddEditDialog(BuildContext context, {Todo? todo}) {
    final isEdit = todo != null;
    final provider = context.read<TodosProvider>();

    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController =
    TextEditingController(text: todo?.description ?? '');
    DateTime? selectedDueDate = todo?.dueDate;
    String? selectedPriority = todo?.priority;

    String? localError;
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final initial = selectedDueDate ?? now;
              final first = DateTime(now.year - 1);
              final last = DateTime(now.year + 5);

              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: initial,
                firstDate: first,
                lastDate: last,
              );

              if (picked != null) {
                setState(() {
                  selectedDueDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                });
              }
            }

            Future<void> submit() async {
              final title = titleController.text.trim();
              final description = descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim();

              if (title.isEmpty) {
                setState(() {
                  localError = 'عنوان نمی‌تواند خالی باشد.';
                });
                return;
              }

              setState(() {
                isSubmitting = true;
                localError = null;
              });

              final result = isEdit
                  ? await provider.updateDetails(
                todo!,
                title: title,
                description: description,
                dueDate: selectedDueDate,
                priority: selectedPriority,
              )
                  : await provider.create(
                title: title,
                description: description,
                dueDate: selectedDueDate,
                priority: selectedPriority,
              );

              if (result.isSuccess) {
                if (!navigator.mounted) return;

                navigator.pop();
                AppNotifier.showSuccess(
                  context,
                  isEdit ? 'Todo با موفقیت ویرایش شد.' : 'Todo با موفقیت ایجاد شد.',
                );
              } else {
                final err = result.requireError;
                setState(() {
                  isSubmitting = false;
                  localError = err.userMessage;
                });
                AppNotifier.showNetworkError(context, err);
              }
            }

            final String buttonLabel;
            if (isSubmitting) {
              buttonLabel = isEdit ? 'در حال ویرایش...' : 'در حال ثبت...';
            } else if (localError != null) {
              buttonLabel =
              isEdit ? 'تلاش مجدد ویرایش' : 'تلاش مجدد ثبت';
            } else {
              buttonLabel = isEdit ? 'ویرایش' : 'ثبت';
            }

            return AlertDialog(
              title: Text(isEdit ? 'ویرایش Todo' : 'افزودن Todo جدید'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (اختیاری)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: isSubmitting ? null : pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due date (اختیاری)',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedDueDate == null
                                        ? 'انتخاب نشده'
                                        : _formatDate(selectedDueDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: selectedDueDate == null
                                          ? Colors.black38
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (selectedDueDate != null)
                                  GestureDetector(
                                    onTap: isSubmitting
                                        ? null
                                        : () {
                                      setState(() {
                                        selectedDueDate = null;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Colors.black38,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedPriority,
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('بدون اولویت'),
                                ),
                                DropdownMenuItem(
                                  value: 'low', // 👈 مقدار ذخیره‌شده در Appwrite
                                  child: Text('پایین'), // 👈 متن فارسی برای نمایش در UI
                                ),
                                DropdownMenuItem(
                                  value: 'medium',
                                  child: Text('متوسط'),
                                ),
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Text('بالا'),
                                ),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (value) {
                                setState(() {
                                  selectedPriority = value;
                                });
                              },
                            ),

                          ),
                        ),
                      ),
                    ],
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        localError!,
                        style: const TextStyle(
                          color: GFColors.DANGER,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 40,
                      child: GFButton(
                        size: GFSize.SMALL,
                        type: GFButtonType.outline,
                        color: GFColors.DARK,
                        onPressed:
                        isSubmitting ? null : () => navigator.pop(),
                        text: 'انصراف',
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: isSubmitting
                          ? Shimmer(
                        child: GFButton(
                          size: GFSize.SMALL,
                          color: GFColors.PRIMARY,
                          onPressed: null,
                          text: buttonLabel,
                        ),
                      )
                          : GFButton(
                        size: GFSize.SMALL,
                        color: GFColors.PRIMARY,
                        onPressed: submit,
                        text: buttonLabel,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------- دیالوگ حذف -----------------

  void _showDeleteDialog(BuildContext context, Todo todo) {
    final provider = context.read<TodosProvider>();

    bool isSubmitting = false;
    String? localError;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> submit() async {
              setState(() {
                isSubmitting = true;
                localError = null;
              });

              final result = await provider.deleteTodo(todo);

              if (result.isSuccess) {
                if (!navigator.mounted) return;

                navigator.pop();
                AppNotifier.showSuccess(context, 'Todo با موفقیت حذف شد.');
              } else {
                final err = result.requireError;
                setState(() {
                  isSubmitting = false;
                  localError = err.userMessage;
                });
                AppNotifier.showNetworkError(context, err);
              }
            }

            final String buttonLabel;
            if (isSubmitting) {
              buttonLabel = 'در حال حذف...';
            } else if (localError != null) {
              buttonLabel = 'تلاش مجدد حذف';
            } else {
              buttonLabel = 'حذف';
            }

            return AlertDialog(
              title: const Text('حذف Todo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('آیا از حذف این Todo مطمئن هستید؟'),
                  const SizedBox(height: 8),
                  Text(
                    todo.title.isEmpty ? '(no title)' : todo.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      localError!,
                      style: const TextStyle(
                        color: GFColors.DANGER,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 40,
                      child: GFButton(
                        size: GFSize.SMALL,
                        type: GFButtonType.outline,
                        color: GFColors.DARK,
                        onPressed:
                        isSubmitting ? null : () => navigator.pop(),
                        text: 'انصراف',
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: isSubmitting
                          ? Shimmer(
                        child: GFButton(
                          size: GFSize.SMALL,
                          color: GFColors.DANGER,
                          onPressed: null,
                          text: buttonLabel,
                        ),
                      )
                          : GFButton(
                        size: GFSize.SMALL,
                        color: GFColors.DANGER,
                        onPressed: submit,
                        text: buttonLabel,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------- کمکی‌ها -----------------

  int _calculateItemCount(TodosProvider provider) {
    var count = provider.todos.length;

    if (provider.isLoadingMore) {
      count += 1;
    } else if (!provider.hasMore && provider.todos.isNotEmpty) {
      count += 1;
    }

    return count;
  }

  Widget _buildEndOfListCard(BuildContext context) {
    return GFCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: EdgeInsets.zero,
      color: GFColors.LIGHT.withOpacity(0.7),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: GFColors.SUCCESS,
          ),
          SizedBox(width: 8),
          Text(
            'دیگه موردی برای نمایش نیست.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
