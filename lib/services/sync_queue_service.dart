import 'dart:convert';
import 'database_helper.dart';

// Simple sync queue stored in SQLite. Records operations that need to be
// retried/synced to the server when the device is online.
// Each row contains an entity type (e.g., 'progress'), an operation, a JSON
// payload and a status ('pending' or 'done'). The queue is read FIFO by
// ordering on `createdAt`.
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

  // Mark an item done after successful sync/upload.
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
