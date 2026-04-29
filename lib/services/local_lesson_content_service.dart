import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class LocalLessonContentService {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<void> cacheQuiz({
    required String quizId,
    required String lessonId,
    required String title,
    required int passingScore,
    required int totalQuestions,
  }) async {
    final db = await _db;
    await db.insert('quizzes', {
      'quizId': quizId,
      'lessonId': lessonId,
      'title': title,
      'passingScore': passingScore,
      'totalQuestions': totalQuestions,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getQuizByLessonId(String lessonId) async {
    final db = await _db;
    final result = await db.query(
      'quizzes',
      where: 'lessonId = ?',
      whereArgs: [lessonId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> cacheQuestions(
    String quizId,
    List<Map<String, dynamic>> questions,
  ) async {
    final db = await _db;

    await db.delete('questions', where: 'quizId = ?', whereArgs: [quizId]);

    for (final question in questions) {
      await db.insert(
        'questions',
        question,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getQuestionsByQuizId(String quizId) async {
    final db = await _db;
    return db.query('questions', where: 'quizId = ?', whereArgs: [quizId]);
  }

  Future<void> cachePractice({
    required String practiceId,
    required String lessonId,
    required String title,
    required String instruction,
    required String starterCode,
    required String expectedOutput,
    required int order,
  }) async {
    final db = await _db;
    await db.insert('practices', {
      'practiceId': practiceId,
      'lessonId': lessonId,
      'title': title,
      'instruction': instruction,
      'starterCode': starterCode,
      'expectedOutput': expectedOutput,
      'practiceOrder': order,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPracticesByLessonId(
    String lessonId,
  ) async {
    final db = await _db;
    return db.query('practices', where: 'lessonId = ?', whereArgs: [lessonId]);
  }
}
