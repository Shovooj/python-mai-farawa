import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'firestore_service.dart';

class LocalLessonContentService {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  final FirestoreService _firestoreService = FirestoreService();

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

  Future<void> markLessonAsDownloaded({
    required String lessonId,
    required bool isDownloaded,
    required bool videoDownloaded,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.insert('downloaded_lessons', {
      'lessonId': lessonId,
      'isDownloaded': isDownloaded ? 1 : 0,
      'videoDownloaded': videoDownloaded ? 1 : 0,
      'downloadedAt': now,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDownloadedLesson(String lessonId) async {
    final db = await _db;
    final result = await db.query(
      'downloaded_lessons',
      where: 'lessonId = ?',
      whereArgs: [lessonId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<bool> isLessonDownloaded(String lessonId) async {
    final row = await getDownloadedLesson(lessonId);
    if (row == null) return false;
    return (row['isDownloaded'] as int? ?? 0) == 1;
  }

  Future<void> updateDownloadedLessonVideoStatus({
    required String lessonId,
    required bool videoDownloaded,
  }) async {
    final db = await _db;
    final existing = await getDownloadedLesson(lessonId);
    final now = DateTime.now().toIso8601String();

    await db.insert('downloaded_lessons', {
      'lessonId': lessonId,
      'isDownloaded': existing == null
          ? 0
          : ((existing['isDownloaded'] as int? ?? 0)),
      'videoDownloaded': videoDownloaded ? 1 : 0,
      'downloadedAt': existing?['downloadedAt'],
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveFullLessonPackage({
    required String lessonId,
    required Map<String, dynamic>? quiz,
    required List<Map<String, dynamic>> questions,
    required List<Map<String, dynamic>> practices,
    bool videoDownloaded = false,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      if (quiz != null) {
        await txn.insert('quizzes', {
          'quizId': quiz['quizId'],
          'lessonId': quiz['lessonId'],
          'title': quiz['title'],
          'passingScore': quiz['passingScore'],
          'totalQuestions': quiz['totalQuestions'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        await txn.delete(
          'questions',
          where: 'quizId = ?',
          whereArgs: [quiz['quizId']],
        );

        for (final question in questions) {
          await txn.insert(
            'questions',
            question,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await txn.delete(
        'practices',
        where: 'lessonId = ?',
        whereArgs: [lessonId],
      );

      for (final practice in practices) {
        await txn.insert(
          'practices',
          practice,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.insert('downloaded_lessons', {
        'lessonId': lessonId,
        'isDownloaded': 1,
        'videoDownloaded': videoDownloaded ? 1 : 0,
        'downloadedAt': now,
        'updatedAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Map<String, dynamic>>> getPracticesByLessonId(
    String lessonId,
  ) async {
    final db = await _db;
    return db.query('practices', where: 'lessonId = ?', whereArgs: [lessonId]);
  }

  Future<void> downloadLessonPackageFromFirestore({
    required String lessonId,
  }) async {
    final quiz = await _firestoreService.getQuizByLessonId(lessonId);

    List<Map<String, dynamic>> questionMaps = [];
    if (quiz != null) {
      final questionStream = await _firestoreService.getQuestionsByQuizId(
        quiz.quizId,
      );
      final questions = await questionStream.first;

      questionMaps = questions
          .map(
            (q) => {
              'questionId': q.questionId,
              'quizId': q.quizId,
              'lessonId': lessonId,
              'questionText': q.questionText,
              'questionTextHa': q.questionTextHa,
              'optionA': q.optionA,
              'optionAHa': q.optionAHa,
              'optionB': q.optionB,
              'optionBHa': q.optionBHa,
              'optionC': q.optionC,
              'optionCHa': q.optionCHa,
              'optionD': q.optionD,
              'optionDHa': q.optionDHa,
              'correctAnswer': q.correctAnswer,
              'order': q.order,
            },
          )
          .toList();
    }

    final practices = await _firestoreService.getPracticesByLessonId(lessonId);

    final practiceMaps = practices
        .map(
          (p) => {
            'practiceId': p.practiceId,
            'lessonId': p.lessonId,
            'title': p.title,
            'instruction': p.instruction,
            'starterCode': p.starterCode,
            'expectedOutput': p.expectedOutput,
            'practiceOrder': p.order,
          },
        )
        .toList();

    await saveFullLessonPackage(
      lessonId: lessonId,
      quiz: quiz == null
          ? null
          : {
              'quizId': quiz.quizId,
              'lessonId': quiz.lessonId,
              'title': quiz.title,
              'passingScore': quiz.passingScore,
              'totalQuestions': quiz.totalQuestions,
            },
      questions: questionMaps,
      practices: practiceMaps,
      videoDownloaded: false,
    );
  }

  Future<bool> isLessonPackageDownloaded(String lessonId) async {
    final db = await _db;

    final quizRows = await db.query(
      'quizzes',
      where: 'lessonId = ?',
      whereArgs: [lessonId],
      limit: 1,
    );

    final practiceRows = await db.query(
      'practices',
      where: 'lessonId = ?',
      whereArgs: [lessonId],
      limit: 1,
    );

    return quizRows.isNotEmpty || practiceRows.isNotEmpty;
  }
}
