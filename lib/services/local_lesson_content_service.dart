import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'firestore_service.dart';

// Manages caching of quiz, question and practice content for offline use.
// Also handles downloading a full lesson package (quiz + questions + practices)
// into local storage. Uses transactions to ensure the package is saved atomically.
class LocalLessonContentService {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> cacheQuiz({
    required String quizId,
    required String lessonId,
    required String title,
    String titleHa = '',
    required int passingScore,
    required int totalQuestions,
  }) async {
    final db = await _db;
    await db.insert('quizzes', {
      'quizId': quizId,
      'lessonId': lessonId,
      'title': title,
      'titleHa': titleHa,
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
    return db.query(
      'questions',
      where: 'quizId = ?',
      whereArgs: [quizId],
      orderBy: '"order" ASC',
    );
  }

  Future<void> cachePractice({
    required String practiceId,
    required String lessonId,
    required String title,
    String titleHa = '',
    required String instruction,
    String instructionHa = '',
    required String starterCode,
    required String expectedOutput,
    String expectedOutputHa = '',
    required int order,
  }) async {
    final db = await _db;
    await db.insert('practices', {
      'practiceId': practiceId,
      'lessonId': lessonId,
      'title': title,
      'titleHa': titleHa,
      'instruction': instruction,
      'instructionHa': instructionHa,
      'starterCode': starterCode,
      'expectedOutput': expectedOutput,
      'expectedOutputHa': expectedOutputHa,
      'practiceOrder': order,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPracticesByLessonId(
    String lessonId,
  ) async {
    final db = await _db;
    return db.query(
      'practices',
      where: 'lessonId = ?',
      whereArgs: [lessonId],
      orderBy: 'practiceOrder ASC',
    );
  }

  Future<void> markLessonAsDownloaded({
    required String userId,
    required String lessonId,
    required bool isDownloaded,
    required bool videoDownloaded,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final existing = await getDownloadedLesson(
      userId: userId,
      lessonId: lessonId,
    );

    await db.insert('downloaded_lessons', {
      'userId': userId,
      'lessonId': lessonId,
      'isDownloaded': isDownloaded ? 1 : 0,
      'videoDownloaded': videoDownloaded ? 1 : 0,
      'downloadedAt': existing?['downloadedAt'] ?? now,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDownloadedLesson({
    required String userId,
    required String lessonId,
  }) async {
    final db = await _db;
    final result = await db.query(
      'downloaded_lessons',
      where: 'userId = ? AND lessonId = ?',
      whereArgs: [userId, lessonId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<bool> isLessonDownloaded({
    required String userId,
    required String lessonId,
  }) async {
    final row = await getDownloadedLesson(userId: userId, lessonId: lessonId);
    if (row == null) return false;
    return (row['isDownloaded'] as int? ?? 0) == 1;
  }

  Future<void> updateDownloadedLessonVideoStatus({
    required String userId,
    required String lessonId,
    required bool videoDownloaded,
  }) async {
    final db = await _db;
    final existing = await getDownloadedLesson(
      userId: userId,
      lessonId: lessonId,
    );
    final now = DateTime.now().toIso8601String();

    await db.insert('downloaded_lessons', {
      'userId': userId,
      'lessonId': lessonId,
      'isDownloaded': (existing?['isDownloaded'] as int? ?? 0),
      'videoDownloaded': videoDownloaded ? 1 : 0,
      'downloadedAt': existing?['downloadedAt'] ?? now,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveFullLessonPackage({
    required String userId,
    required String lessonId,
    required Map<String, dynamic>? quiz,
    required List<Map<String, dynamic>> questions,
    required List<Map<String, dynamic>> practices,
    bool videoDownloaded = false,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    // Transaction ensures that all parts of the package are saved together.
    await db.transaction((txn) async {
      if (quiz != null) {
        await txn.insert('quizzes', {
          'quizId': quiz['quizId'],
          'lessonId': quiz['lessonId'],
          'title': quiz['title'],
          'titleHa': quiz['titleHa'] ?? '',
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
        'userId': userId,
        'lessonId': lessonId,
        'isDownloaded': 1,
        'videoDownloaded': videoDownloaded ? 1 : 0,
        'downloadedAt': now,
        'updatedAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> downloadLessonPackageFromFirestore({
    required String userId,
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
            'titleHa': p.titleHa,
            'instruction': p.instruction,
            'instructionHa': p.instructionHa,
            'starterCode': p.starterCode,
            'expectedOutput': p.expectedOutput,
            'expectedOutputHa': p.expectedOutputHa,
            'practiceOrder': p.order,
          },
        )
        .toList();

    await saveFullLessonPackage(
      userId: userId,
      lessonId: lessonId,
      quiz: quiz == null
          ? null
          : {
              'quizId': quiz.quizId,
              'lessonId': quiz.lessonId,
              'title': quiz.title,
              'titleHa': quiz.titleHa,
              'passingScore': quiz.passingScore,
              'totalQuestions': quiz.totalQuestions,
            },
      questions: questionMaps,
      practices: practiceMaps,
      videoDownloaded: false,
    );
  }

  Future<bool> isLessonPackageDownloaded({
    required String userId,
    required String lessonId,
  }) async {
    final row = await getDownloadedLesson(userId: userId, lessonId: lessonId);
    if (row == null) return false;

    final downloaded = (row['isDownloaded'] as int? ?? 0) == 1;
    if (!downloaded) return false;

    final quiz = await getQuizByLessonId(lessonId);
    final practices = await getPracticesByLessonId(lessonId);

    if (quiz == null) return false;
    if (practices.isEmpty) return false;

    final quizId = quiz['quizId'] as String?;
    if (quizId == null || quizId.isEmpty) return false;

    final questions = await getQuestionsByQuizId(quizId);
    if (questions.isEmpty) return false;

    return true;
  }

  Future<bool> hasCompleteLessonPackage({
    required String userId,
    required String lessonId,
  }) async {
    final downloaded = await getDownloadedLesson(
      userId: userId,
      lessonId: lessonId,
    );
    if (downloaded == null) return false;
    if ((downloaded['isDownloaded'] as int? ?? 0) != 1) return false;

    final quiz = await getQuizByLessonId(lessonId);
    if (quiz == null) return false;

    final quizId = quiz['quizId'] as String?;
    if (quizId == null || quizId.isEmpty) return false;

    final questions = await getQuestionsByQuizId(quizId);
    if (questions.isEmpty) return false;

    final practices = await getPracticesByLessonId(lessonId);
    if (practices.isEmpty) return false;

    return true;
  }
}
