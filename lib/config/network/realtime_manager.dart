
import 'dart:async';

import 'package:appwrite/appwrite.dart';

import 'appwrite_client.dart';

enum RealtimeAction {
  create,
  update,
  delete,
  unknown,
}

class RealtimeEvent<T> {
  final RealtimeAction action;
  final T? data;
  final String? documentId;
  final Map<String, dynamic> raw;

  RealtimeEvent({
    required this.action,
    required this.raw,
    this.data,
    this.documentId,
  });

  @override
  String toString() {
    return 'RealtimeEvent(action: $action, documentId: $documentId, data: $data)';
  }
}

class RealtimeManager {
  RealtimeManager._internal();

  static final RealtimeManager instance = RealtimeManager._internal();

  final Map<String, RealtimeSubscription> _subscriptions = {};
  final Map<String, StreamController<RealtimeEvent<Map<String, dynamic>>>>
  _controllers = {};

  Realtime get _realtime => AppwriteClient.instance.realtime;

  String _channelsKey(List<String> channels) => channels.join(',');

  Stream<RealtimeEvent<Map<String, dynamic>>> subscribeRaw(
      List<String> channels,
      ) {
    final key = _channelsKey(channels);

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller =
    StreamController<RealtimeEvent<Map<String, dynamic>>>.broadcast();

    final subscription = _realtime.subscribe(channels);

    subscription.stream.listen(
          (RealtimeMessage message) {
        try {
          final payload =
          Map<String, dynamic>.from(message.payload);
          final events = message.events;
          final action = _extractAction(events);
          final documentId = payload['\$id']?.toString();

          final event = RealtimeEvent<Map<String, dynamic>>(
            action: action,
            raw: payload,
            data: payload,
            documentId: documentId,
          );

          controller.add(event);
        } catch (_) {
          // در صورت نیاز می‌توانی اینجا لاگ بگیری
        }
      },
      onError: (error, stackTrace) {
        // در صورت نیاز می‌توانی خطا را لاگ کنی
      },
      onDone: () {
        // فعلاً کاری نمی‌کنیم
      },
      cancelOnError: false,
    );

    _subscriptions[key] = subscription;
    _controllers[key] = controller;

    return controller.stream;
  }

  Stream<RealtimeEvent<Map<String, dynamic>>> subscribeCollectionRaw({
    required String databaseId,
    required String collectionId,
  }) {
    final channel =
        'databases.$databaseId.collections.$collectionId.documents';
    return subscribeRaw([channel]);
  }

  Stream<RealtimeEvent<T>> subscribeCollection<T>({
    required String databaseId,
    required String collectionId,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    final rawStream = subscribeCollectionRaw(
      databaseId: databaseId,
      collectionId: collectionId,
    );

    return rawStream.map((rawEvent) {
      final data = rawEvent.data != null
          ? fromJson(rawEvent.data!)
          : null;
      return RealtimeEvent<T>(
        action: rawEvent.action,
        raw: rawEvent.raw,
        data: data,
        documentId: rawEvent.documentId,
      );
    });
  }

  void unsubscribe(List<String> channels) {
    final key = _channelsKey(channels);

    _subscriptions.remove(key)?.close();
    _controllers.remove(key)?.close();
  }

  void unsubscribeCollection({
    required String databaseId,
    required String collectionId,
  }) {
    final channel =
        'databases.$databaseId.collections.$collectionId.documents';
    unsubscribe([channel]);
  }

  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.close();
    }
    _subscriptions.clear();

    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }

  RealtimeAction _extractAction(List<String> events) {
    if (events.any((e) => e.endsWith('.create'))) {
      return RealtimeAction.create;
    }
    if (events.any((e) => e.endsWith('.update'))) {
      return RealtimeAction.update;
    }
    if (events.any((e) => e.endsWith('.delete'))) {
      return RealtimeAction.delete;
    }
    return RealtimeAction.unknown;
  }
}
