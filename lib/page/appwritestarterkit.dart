import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite_flutter_starter_kit/state/connection_provider.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class AppwriteStarterKit extends StatelessWidget {
  const AppwriteStarterKit({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionProvider>();

    final Color statusColor;
    final String statusText;

    if (connection.lastSuccess == null) {
      statusColor = GFColors.SECONDARY;
      statusText = 'Not pinged yet';
    } else if (connection.lastSuccess == true) {
      statusColor = GFColors.SUCCESS;
      statusText = 'Connected';
    } else {
      statusColor = GFColors.DANGER;
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
            // وضعیت اتصال - با GFCard + GFListTile
            GFCard(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              content: GFListTile(
                avatar: GFAvatar(
                  backgroundColor: statusColor,
                  child: const Icon(
                    Icons.cloud,
                    color: Colors.white,
                  ),
                ),
                titleText: statusText,
                subTitle: Text(
                  connection.lastMessage ??
                      'Press "Ping Appwrite" to test connection.',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // دکمه‌ی Ping و Clear Logs با GetWidget + Shimmer
            Row(
              children: [
                Expanded(
                  child: connection.isPinging
                      ? Shimmer(
                    child: GFButton(
                      onPressed: null,
                      icon: const Icon(Icons.wifi_tethering),
                      text: 'Pinging...',
                      color: GFColors.PRIMARY,
                      fullWidthButton: true,
                    ),
                  )
                      : GFButton(
                    onPressed: () => connection.sendPing(),
                    icon: const Icon(Icons.wifi_tethering),
                    text: 'Ping Appwrite',
                    color: GFColors.PRIMARY,
                    fullWidthButton: true,
                  ),
                ),
                const SizedBox(width: 8),
                GFIconButton(
                  icon: const Icon(Icons.delete_sweep),
                  color: GFColors.DANGER,
                  type: GFButtonType.outline,
                  onPressed: connection.logs.isEmpty
                      ? null
                      : connection.clearLogs,
                  tooltip: 'Clear logs',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // لیست لاگ‌ها با GFCard
            Expanded(
              child: GFCard(
                elevation: 2,
                padding: EdgeInsets.zero,
                content: Column(
                  mainAxisSize: MainAxisSize.min, // shrink-wrap
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
                    Flexible(
                      fit: FlexFit.loose,
                      child: SizedBox(
                        height: 250, // ارتفاع محدود برای لاگ‌ها
                        child: connection.logs.isEmpty
                            ? const Center(
                          child: Text(
                            'No logs yet. Hit "Ping Appwrite" to start.',
                            textAlign: TextAlign.center,
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
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: GFColors.LIGHT.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                log,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
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
