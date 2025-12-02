import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appwrite_flutter_starter_kit/state/connection_provider.dart';

/// صفحه‌ی تست اتصال به Appwrite
///
/// این ویجت را در main.dart روی route `/starter-kit` وصل کرده‌ایم.
class AppwriteStarterKit extends StatelessWidget {
  const AppwriteStarterKit({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionProvider>();

    final Color statusColor;
    final String statusText;

    if (connection.lastSuccess == null) {
      statusColor = Colors.grey;
      statusText = 'Not pinged yet';
    } else if (connection.lastSuccess == true) {
      statusColor = Colors.green;
      statusText = 'Connected';
    } else {
      statusColor = Colors.red;
      statusText = 'Connection error';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appwrite Starter Kit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // وضعیت اتصال
            Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor,
                  child: const Icon(
                    Icons.cloud,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                subtitle: Text(
                  connection.lastMessage ??
                      'Press "Ping Appwrite" to test connection.',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // دکمه‌های Ping و Clear Logs
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: connection.isPinging
                        ? null
                        : () => connection.sendPing(),
                    icon: connection.isPinging
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.wifi_tethering),
                    label: Text(
                      connection.isPinging
                          ? 'Pinging...'
                          : 'Ping Appwrite',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: connection.logs.isEmpty
                      ? null
                      : connection.clearLogs,
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Clear logs',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // لیست لاگ‌ها
            Expanded(
              child: Card(
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'Logs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: connection.logs.isEmpty
                          ? const Center(
                        child: Text(
                          'No logs yet. Hit "Ping Appwrite" to start.',
                        ),
                      )
                          : ListView.separated(
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: connection.logs.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final log = connection.logs[index];
                          return Text(
                            log,
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
