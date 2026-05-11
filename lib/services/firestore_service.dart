import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';
import '../models/practice_model.dart';
import '../models/progress_model.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';

// Thin wrapper around Firestore calls used by the app.
// Notes:
// - Progress documents use a composite id `${userId}_${lessonId}`.
// - `saveLessonProgress` uses `FieldValue.serverTimestamp()` for lastAccessed
//   and completedAt to ensure server time is authoritative.
// - Progress is merged with existing documents to avoid overwriting other fields.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Lesson>> getPublishedLessons() async {
    final snapshot = await _firestore
        .collection('lessons')
        .where('isPublished', isEqualTo: true)
        .orderBy('lessonNumber')
        .get();

    return snapshot.docs.map((doc) => Lesson.fromMap(doc.data())).toList();
  }

  Future<Lesson?> getLessonById(String lessonId) async {
    final snapshot = await _firestore
        .collection('lessons')
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Lesson.fromMap(snapshot.docs.first.data());
  }

  Future<List<PracticeModel>> getPracticesByLessonId(String lessonId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('practices')
        .where('lessonId', isEqualTo: lessonId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return PracticeModel(
        practiceId: data['practiceId']?.toString() ?? doc.id,
        lessonId: data['lessonId']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        instruction: data['instruction']?.toString() ?? '',
        starterCode: data['starterCode']?.toString() ?? '',
        expectedOutput: data['expectedOutput']?.toString() ?? '',
        order: data['order'] is int
            ? data['order'] as int
            : int.tryParse(data['order']?.toString() ?? '0') ?? 0,
        titleHa: data['titleHa']?.toString() ?? '',
        instructionHa: data['instructionHa']?.toString() ?? '',
        expectedOutputHa: data['expectedOutputHa']?.toString() ?? '',
      );
    }).toList();
  }

  Future<QuizModel?> getQuizByLessonId(String lessonId) async {
    final snapshot = await _firestore
        .collection('quizzes')
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return QuizModel.fromMap(snapshot.docs.first.data());
  }

  Future<Stream<List<QuestionModel>>> getQuestionsByQuizId(
    String quizId,
  ) async {
    return _firestore
        .collection('questions')
        .where('quizId', isEqualTo: quizId)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuestionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<ProgressModel?> getProgress(String userId, String lessonId) async {
    final docId = '${userId}_$lessonId';
    final doc = await _firestore.collection('progress').doc(docId).get();

    if (!doc.exists || doc.data() == null) return null;

    return ProgressModel.fromMap(doc.data()!);
  }

  // Save or merge progress for a lesson. Only provided fields are written.
  // This lets callers update e.g. practiceCompleted without overwriting score.
  Future<void> saveLessonProgress({
    required String userId,
    required String lessonId,
    bool? lessonCompleted,
    bool? practiceCompleted,
    bool? quizCompleted,
    bool? videoViewed,
    int? score,
  }) async {
    final docId = '${userId}_$lessonId';

    final Map<String, dynamic> data = {
      'progressId': docId,
      'userId': userId,
      'lessonId': lessonId,
      'lastAccessed': FieldValue.serverTimestamp(),
    };

    if (lessonCompleted != null) data['lessonCompleted'] = lessonCompleted;
    if (practiceCompleted != null) {
      data['practiceCompleted'] = practiceCompleted;
    }
    if (quizCompleted != null) data['quizCompleted'] = quizCompleted;
    if (videoViewed != null) data['videoViewed'] = videoViewed;
    if (score != null) data['score'] = score;

    if (lessonCompleted == true) {
      data['completedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore
        .collection('progress')
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }

  Future<Lesson?> getLessonByLessonNumber(int lessonNumber) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .where('lessonNumber', isEqualTo: lessonNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return Lesson.fromMap(doc.data());
  }
}
