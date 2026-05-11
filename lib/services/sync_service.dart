import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';

// A generic sync service that mirrors queue entries into Firestore.
// Note: the application also contains a more specialized `ProgressSyncService`.
// Keep behavior here conservative: failures leave the queue item as pending.
class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addToQueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('sync_queue', {
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> syncPendingProgress() async {
    final db = await DatabaseHelper.instance.database;

    final pendingItems = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );

    for (final item in pendingItems) {
      try {
        final payload = jsonDecode(item['payload'] as String);

        if (item['entityType'] == 'progress' && item['operation'] == 'upsert') {
          final userId = payload['userId'];
          final lessonId = payload['lessonId'];

          // Write to a nested collection under users to match a user-scoped
          // progress storage model. Uses merge to preserve other fields.
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('progress')
              .doc(lessonId)
              .set(payload, SetOptions(merge: true));
        }

        await db.update(
          'sync_queue',
          {'status': 'synced'},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      } catch (e) {
        // On error we leave the item as pending so it can be retried later.
      }
    }
  }
}
