import 'package:appwrite_flutter_starter_kit/state/test_strings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite_flutter_starter_kit/data/models/test_string.dart';
import 'package:appwrite_flutter_starter_kit/utils/app_notifier.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class TestStringsPage extends StatelessWidget {
  static const String routeName = '/test-strings';

  const TestStringsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestStringsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'test_strings (Realtime + Provider + Network Layer)',
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
              child: provider.loading && provider.rows.isEmpty
              // لود اولیه → کارت‌های شیمری
                  ? _buildShimmerList(context)
                  : provider.rows.isEmpty
                  ? const Center(child: Text('No rows yet'))
                  : NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (provider.hasMore &&
                      !provider.isLoadingMore &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                    provider.loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: _calculateItemCount(provider),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    // ایندکس اضافه برای حالت لود بیشتر / پایان لیست
                    if (index >= provider.rows.length) {
                      if (provider.isLoadingMore) {
                        // کارت شیمری برای loadMore
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildShimmerCard(context),
                        );
                      }

                      if (!provider.hasMore && provider.rows.isNotEmpty) {
                        // کارت پایان لیست
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildEndOfListCard(context),
                        );
                      }
                    }

                    // آیتم‌های معمولی
                    final row = provider.rows[index];

                    return GFCard(
                      padding: const EdgeInsets.all(0),
                      margin: EdgeInsets.zero,
                      content: GFListTile(
                        titleText: row.text.isEmpty ? '(no text)' : row.text,
                        subTitleText: 'ID: ${row.id}',
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GFIconButton(
                              icon: const Icon(Icons.edit),
                              type: GFButtonType.transparent,
                              onPressed: () =>
                                  _showAddEditDialog(context, row: row),
                            ),
                            GFIconButton(
                              icon: const Icon(Icons.delete),
                              color: GFColors.DANGER,
                              type: GFButtonType.transparent,
                              onPressed: () => _showDeleteDialog(context, row),
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

  // ----------------- SHIMMER: لیست اسکلت کارت‌ها برای لود اولیه -----------------

  Widget _buildShimmerList(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildShimmerCard(context),
    );
  }

  // یک کارت شیمری (اسکلتی) برای حالت لودینگ
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
                    width: 140,
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

  // ----------------- دیالوگ مشترک افزودن / ویرایش (با GFButton + Shimmer) -----------------

  void _showAddEditDialog(BuildContext context, {TestString? row}) {
    final isEdit = row != null;
    final provider = context.read<TestStringsProvider>();
    final controller = TextEditingController(text: row?.text ?? '');

    String? localError;
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> submit() async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                setState(() {
                  localError = 'متن نمی‌تواند خالی باشد.';
                });
                return;
              }

              setState(() {
                isSubmitting = true;
                localError = null;
              });

              final result = isEdit
                  ? await provider.update(row!, text)
                  : await provider.create(text);

              if (result.isSuccess) {
                Navigator.of(dialogContext).pop();
                AppNotifier.showSuccess(
                  context,
                  isEdit ? 'با موفقیت ویرایش شد.' : 'با موفقیت ثبت شد.',
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
              title: Text(isEdit ? 'ویرایش متن' : 'افزودن متن جدید'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Text',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      if (!isSubmitting) {
                        submit();
                      }
                    },
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
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        text: 'انصراف',
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: isSubmitting
                      // دکمه شیمری در حال ارسال
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

  // ----------------- دیالوگ حذف با GFButton + Shimmer -----------------

  void _showDeleteDialog(BuildContext context, TestString row) {
    final provider = context.read<TestStringsProvider>();

    bool isSubmitting = false;
    String? localError;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> submit() async {
              setState(() {
                isSubmitting = true;
                localError = null;
              });

              final result = await provider.delete(row);

              if (result.isSuccess) {
                Navigator.of(dialogContext).pop();
                AppNotifier.showSuccess(context, 'با موفقیت حذف شد.');
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
              title: const Text('حذف آیتم'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('آیا از حذف این آیتم مطمئن هستید؟'),
                  const SizedBox(height: 8),
                  Text(
                    row.text.isEmpty ? '(no text)' : row.text,
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
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
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


  int _calculateItemCount(TestStringsProvider provider) {
    var count = provider.rows.length;

    // اگر در حال لود صفحه بعدی هستیم → یک آیتم شیمری انتها
    if (provider.isLoadingMore) {
      count += 1;
    } else if (!provider.hasMore && provider.rows.isNotEmpty) {
      // اگر دیگر دیتای بیشتری وجود ندارد → یک کارت "پایان لیست"
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
