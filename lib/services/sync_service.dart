import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';

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
        // leave as pending
      }
    }
  }
}
