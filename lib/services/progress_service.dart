import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/progress_model.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No signed-in user found.');
    }
    return user.uid;
  }

  String _progressDocId(String lessonId) => '${_uid}_$lessonId';

  Future<void> saveQuizProgress({
    required String lessonId,
    required int score,
  }) async {
    final docId = _progressDocId(lessonId);
    final docRef = _firestore.collection('progress').doc(docId);

    final existingDoc = await docRef.get();
    final data = existingDoc.data() ?? {};

    final bool existingQuizCompleted = data['quizCompleted'] ?? false;
    final int existingScore = data['score'] ?? 0;

    final bool finalQuizCompleted = true; // once you call this, quiz is done
    final int finalScore = score > existingScore ? score : existingScore;

    await docRef.set({
      'progressId': docId,
      'userId': _uid,
      'lessonId': lessonId,
      'quizCompleted': finalQuizCompleted,
      'score': finalScore,
    }, SetOptions(merge: true));

    await updateLessonCompleted(lessonId: lessonId);
  }

  Future<void> savePracticeProgress({required String lessonId}) async {
    final docId = _progressDocId(lessonId);
    final docRef = _firestore.collection('progress').doc(docId);

    final existingDoc = await docRef.get();
    final data = existingDoc.data() ?? {};

    final bool existingPracticeCompleted = data['practiceCompleted'] ?? false;

    final bool finalPracticeCompleted = existingPracticeCompleted || true;

    await docRef.set({
      'progressId': docId,
      'userId': _uid,
      'lessonId': lessonId,
      'practiceCompleted': finalPracticeCompleted,
    }, SetOptions(merge: true));

    await updateLessonCompleted(lessonId: lessonId);
  }

  Future<void> saveVideoProgress({
    required String lessonId,
    required int positionSeconds,
    required int durationSeconds,
    required bool videoViewed,
  }) async {
    final docId = _progressDocId(lessonId);
    final docRef = _firestore.collection('progress').doc(docId);

    final existingDoc = await docRef.get();
    final existingData = existingDoc.data() ?? {};

    final bool existingVideoViewed = existingData['videoViewed'] ?? false;
    final int existingPosition = existingData['videoPositionSeconds'] ?? 0;
    final int existingDuration = existingData['videoDurationSeconds'] ?? 0;

    final bool finalVideoViewed = existingVideoViewed || videoViewed;
    final int finalPosition = positionSeconds > existingPosition
        ? positionSeconds
        : existingPosition;
    final int finalDuration = durationSeconds > existingDuration
        ? durationSeconds
        : existingDuration;

    await docRef.set({
      'progressId': docId,
      'userId': _uid,
      'lessonId': lessonId,
      'videoPositionSeconds': finalPosition,
      'videoDurationSeconds': finalDuration,
      'videoViewed': finalVideoViewed,
    }, SetOptions(merge: true));

    await updateLessonCompleted(lessonId: lessonId);
  }

  Future<void> updateLessonCompleted({required String lessonId}) async {
    final docId = _progressDocId(lessonId);
    final docRef = _firestore.collection('progress').doc(docId);

    final doc = await docRef.get();
    final data = doc.data() ?? {};

    final bool quizCompleted = data['quizCompleted'] ?? false;
    final bool practiceCompleted = data['practiceCompleted'] ?? false;
    final bool videoViewed = data['videoViewed'] ?? false;
    final bool existingLessonCompleted = data['lessonCompleted'] ?? false;

    final bool lessonCompleted =
        existingLessonCompleted ||
        (quizCompleted && practiceCompleted && videoViewed);

    await docRef.set({
      'lessonCompleted': lessonCompleted,
    }, SetOptions(merge: true));
  }

  Stream<List<ProgressModel>> getUserProgressStream() {
    return _firestore
        .collection('progress')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProgressModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<List<ProgressModel>> getUserProgressOnce() async {
    final snapshot = await _firestore
        .collection('progress')
        .where('userId', isEqualTo: _uid)
        .get();

    return snapshot.docs
        .map((doc) => ProgressModel.fromMap(doc.data()))
        .toList();
  }

  Future<ProgressModel?> getUserProgressForLesson(String lessonId) async {
    final docId = _progressDocId(lessonId);

    final doc = await _firestore.collection('progress').doc(docId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ProgressModel.fromMap(doc.data()!);
  }

  Future<void> markVideoViewed(String docId) async {
    await _firestore.collection('progress').doc(docId).set({
      'videoViewed': true,
    }, SetOptions(merge: true));

    final lessonId = docId.replaceFirst('${_uid}_', '');
    await updateLessonCompleted(lessonId: lessonId);
  }

  Future<void> markQuizCompleted(String docId, int score) async {
    await _firestore.collection('progress').doc(docId).set({
      'quizCompleted': true,
      'score': score,
    }, SetOptions(merge: true));

    final lessonId = docId.replaceFirst('${_uid}_', '');
    await updateLessonCompleted(lessonId: lessonId);
  }

  Future<void> markPracticeCompleted(String docId) async {
    await _firestore.collection('progress').doc(docId).set({
      'practiceCompleted': true,
    }, SetOptions(merge: true));

    final lessonId = docId.replaceFirst('${_uid}_', '');
    await updateLessonCompleted(lessonId: lessonId);
  }

  Future<void> markLessonCompleted(String docId) async {
    await _firestore.collection('progress').doc(docId).set({
      'lessonCompleted': true,
    }, SetOptions(merge: true));
  }
}
