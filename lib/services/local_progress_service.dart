import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import '../models/progress_model.dart';
import 'database_helper.dart';

class LocalProgressService {
  // Singleton — one instance, one lock, no cross-instance race conditions
  LocalProgressService._internal();
  static final LocalProgressService instance = LocalProgressService._internal();
  factory LocalProgressService() => instance;

  final Lock _lock = Lock();

  Future<Database> get _db async => DatabaseHelper.instance.database;

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

  Future<ProgressModel?> getLocalProgressForLesson({
    required String userId,
    required String lessonId,
  }) async {
    final db = await _db;
    final result = await db.query(
      'local_progress',
      where: 'userId = ? AND lessonId = ?',
      whereArgs: [userId, lessonId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    debugPrint(
      'RAW SQLITE READ ROW -> ${result.isNotEmpty ? result.first : 'NO ROW'}',
    );
    return ProgressModel.fromMap(result.first);
  }

  Future<void> upsertLocalProgress({
    required String progressId,
    required String userId,
    required String lessonId,
    bool? lessonCompleted,
    bool? practiceCompleted,
    bool? quizCompleted,
    bool? videoViewed,
    int? score,
    int? videoPositionSeconds,
    int? videoDurationSeconds,
  }) async {
    await _lock.synchronized(() async {
      final db = await _db;

      final existing = await getLocalProgressForLesson(
        userId: userId,
        lessonId: lessonId,
      );

      final currentPracticeCompleted = existing?.practiceCompleted ?? false;
      final currentQuizCompleted = existing?.quizCompleted ?? false;
      final currentVideoViewed = existing?.videoViewed ?? false;
      final currentScore = existing?.score ?? 0;
      final currentVideoPosition = existing?.videoPositionSeconds ?? 0;
      final currentVideoDuration = existing?.videoDurationSeconds ?? 0;

      final finalQuizCompleted =
          currentQuizCompleted || (quizCompleted ?? false);
      final finalPracticeCompleted =
          currentPracticeCompleted || (practiceCompleted ?? false);
      final finalVideoViewed = currentVideoViewed || (videoViewed ?? false);

      final finalScore = score != null
          ? (score > currentScore ? score : currentScore)
          : currentScore;

      final finalVideoPosition = videoPositionSeconds != null
          ? (videoPositionSeconds > currentVideoPosition
                ? videoPositionSeconds
                : currentVideoPosition)
          : currentVideoPosition;

      final finalVideoDuration = videoDurationSeconds != null
          ? (videoDurationSeconds > currentVideoDuration
                ? videoDurationSeconds
                : currentVideoDuration)
          : currentVideoDuration;

      final finalLessonCompleted =
          finalVideoViewed && finalQuizCompleted && finalPracticeCompleted;

      await db.insert('local_progress', {
        'progressId': progressId,
        'userId': userId,
        'lessonId': lessonId,
        'lessonCompleted': finalLessonCompleted ? 1 : 0,
        'practiceCompleted': finalPracticeCompleted ? 1 : 0,
        'quizCompleted': finalQuizCompleted ? 1 : 0,
        'videoViewed': finalVideoViewed ? 1 : 0,
        'score': finalScore,
        'videoPositionSeconds': finalVideoPosition,
        'videoDurationSeconds': finalVideoDuration,
        'updatedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final insertedRows = await db.query(
        'local_progress',
        where: 'userId = ? AND lessonId = ?',
        whereArgs: [userId, lessonId],
        limit: 1,
      );

      debugPrint(
        'RAW SQLITE ROW AFTER UPSERT -> ${insertedRows.isNotEmpty ? insertedRows.first : 'NO ROW'}',
      );

      debugPrint(
        'LOCAL PROGRESS SAVED -> '
        'lessonId=$lessonId, '
        'quizCompleted=$finalQuizCompleted, '
        'practiceCompleted=$finalPracticeCompleted, '
        'videoViewed=$finalVideoViewed, '
        'lessonCompleted=$finalLessonCompleted, '
        'score=$finalScore, '
        'videoPositionSeconds=$finalVideoPosition, '
        'videoDurationSeconds=$finalVideoDuration',
      );
    });
  }

  bool isLessonCompleted({
    required bool videoViewed,
    required bool quizCompleted,
    required bool practiceCompleted,
  }) {
    return videoViewed && quizCompleted && practiceCompleted;
  }

  Future<void> saveLessonProgress({
    required String progressId,
    required String userId,
    required String lessonId,
    bool? videoViewed,
    bool? quizCompleted,
    bool? practiceCompleted,
    int? score,
    int? videoPositionSeconds,
    int? videoDurationSeconds,
  }) async {
    await upsertLocalProgress(
      progressId: progressId,
      userId: userId,
      lessonId: lessonId,
      practiceCompleted: practiceCompleted,
      quizCompleted: quizCompleted,
      videoViewed: videoViewed,
      score: score,
      videoPositionSeconds: videoPositionSeconds,
      videoDurationSeconds: videoDurationSeconds,
    );

    debugPrint(
      'LOCAL PROGRESS SAVE REQUESTED -> '
      'lessonId=$lessonId, '
      'quizCompleted=$quizCompleted, '
      'practiceCompleted=$practiceCompleted, '
      'videoViewed=$videoViewed, '
      'score=$score, '
      'videoPositionSeconds=$videoPositionSeconds, '
      'videoDurationSeconds=$videoDurationSeconds',
    );
  }
}
