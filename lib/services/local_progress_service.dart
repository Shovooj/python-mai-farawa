import 'package:sqflite/sqflite.dart';
import '../models/progress_model.dart';
import 'database_helper.dart'; // if you have one

class LocalProgressService {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<ProgressModel>> getUserLocalProgress(String userId) async {
    final db = await _db;

    final rows = await db.query(
      'local_progress',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'lessonId ASC',
    );

    return rows.map((row) => ProgressModel.fromMap(row)).toList();
  }

  Future<void> upsertLocalProgress({
    required String progressId,
    required String userId,
    required String lessonId,
    required bool lessonCompleted,
    required bool practiceCompleted,
    required bool quizCompleted,
    required bool videoViewed,
    required int score,
    required int videoPositionSeconds,
    required int videoDurationSeconds,
  }) async {
    final db = await _db;

    await db.insert('local_progress', {
      'progressId': progressId,
      'userId': userId,
      'lessonId': lessonId,
      'lessonCompleted': lessonCompleted ? 1 : 0,
      'practiceCompleted': practiceCompleted ? 1 : 0,
      'quizCompleted': quizCompleted ? 1 : 0,
      'videoViewed': videoViewed ? 1 : 0,
      'score': score,
      'videoPositionSeconds': videoPositionSeconds,
      'videoDurationSeconds': videoDurationSeconds,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
