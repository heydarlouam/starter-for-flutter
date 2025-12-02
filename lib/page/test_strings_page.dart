// import 'package:appwrite_flutter_starter_kit/state/test_strings_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// class TestStringsPage extends StatelessWidget {
//   static const String routeName = '/test-strings';
//
//   const TestStringsPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<TestStringsProvider>();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'test_strings (Realtime + Provider + Network Layer)',
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             if (provider.error != null)
//               Container(
//                 margin: const EdgeInsets.only(bottom: 8),
//                 padding: const EdgeInsets.all(8),
//                 color: Colors.redAccent.withOpacity(0.1),
//                 child: Text(
//                   provider.error!,
//                   style: const TextStyle(color: Colors.red),
//                 ),
//               ),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: provider.textController,
//                     decoration: const InputDecoration(
//                       labelText: 'New text',
//                       border: OutlineInputBorder(),
//                     ),
//                     onSubmitted: (_) => provider.createRow(),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: provider.createRow,
//                   child: const Text('Add'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (provider.loading)
//               const Center(child: CircularProgressIndicator())
//             else
//               Expanded(
//                 child: provider.rows.isEmpty
//                     ? const Center(child: Text('No rows yet'))
//                     : ListView.separated(
//                   itemCount: provider.rows.length,
//                   separatorBuilder: (_, __) => const Divider(),
//                   itemBuilder: (context, index) {
//                     final row = provider.rows[index];
//
//                     return ListTile(
//                       title: Text(
//                         row.text.isEmpty ? '(no text)' : row.text,
//                       ),
//                       subtitle: Text('ID: ${row.id}'),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.edit),
//                             onPressed: () =>
//                                 provider.updateRow(context, row),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete),
//                             onPressed: () =>
//                                 provider.deleteRow(row),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:appwrite_flutter_starter_kit/state/test_strings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (provider.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                color: Colors.redAccent.withOpacity(0.1),
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: provider.textController,
                    decoration: const InputDecoration(
                      labelText: 'New text',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => provider.createRow(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: provider.createRow,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.loading && provider.rows.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.rows.isEmpty
                  ? const Center(child: Text('No rows yet'))
                  : NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  // وقتی نزدیک انتهای لیست شد، صفحه بعدی را بگیر
                  if (provider.hasMore &&
                      !provider.isLoadingMore &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                    provider.loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: provider.rows.length +
                      (provider.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    // آیتم اضافه برای لودر انتهای لیست
                    if (index >= provider.rows.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final row = provider.rows[index];

                    return ListTile(
                      title: Text(
                        row.text.isEmpty ? '(no text)' : row.text,
                      ),
                      subtitle: Text('ID: ${row.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                provider.updateRow(context, row),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                provider.deleteRow(row),
                          ),
                        ],
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
}
