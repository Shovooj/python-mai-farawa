import 'dart:convert';
import 'database_helper.dart';

class SyncQueueService {
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

  Future<List<Map<String, dynamic>>> getPendingQueueItems() async {
    final db = await DatabaseHelper.instance.database;

    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> markQueueItemDone(int id) async {
    final db = await DatabaseHelper.instance.database;

    await db.update(
      'sync_queue',
      {'status': 'done'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
