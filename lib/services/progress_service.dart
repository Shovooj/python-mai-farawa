import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/progress_model.dart';
import 'local_progress_service.dart';

// High-level progress manager that uses local progress storage first and
// syncs to Firestore to keep server-side state up-to-date.
// Streams local progress updates so UI can react immediately.
class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalProgressService _localProgressService = LocalProgressService();

  final StreamController<List<ProgressModel>> _progressController =
      StreamController<List<ProgressModel>>.broadcast();

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No signed-in user found.');
    }
    return user.uid;
  }

  String _progressDocId(String lessonId) => '${_uid}_$lessonId';

  final LocalProgressService localProgressService = LocalProgressService();

  final StreamController<List<ProgressModel>> progressController =
      StreamController<List<ProgressModel>>.broadcast();

  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in user found.');
    return user.uid;
  }

  // Returns a stream that first emits the current local progress snapshot and
  // then any subsequent updates pushed to `_progressController`.
  Stream<List<ProgressModel>> getUserProgressStream() async* {
    final initialRows = await _localProgressService.getUserLocalProgress(_uid);
    yield initialRows;
    yield* _progressController.stream;
  }

  Future<void> refreshLocalProgress() async {
    final rows = await _localProgressService.getUserLocalProgress(_uid);
    _progressController.add(rows);
  }

  Future<void> refreshLocalProgressStream() async {
    final rows = await _localProgressService.getUserLocalProgress(_uid);
    if (!_progressController.isClosed) {
      _progressController.add(rows);
    }
  }

  Future<List<ProgressModel>> getUserProgressOnce() async {
    return _localProgressService.getUserLocalProgress(_uid);
  }

  Future<ProgressModel?> getUserProgressForLesson(String lessonId) async {
    return _localProgressService.getLocalProgressForLesson(
      userId: _uid,
      lessonId: lessonId,
    );
  }

  // Pushes the full local progress record for a lesson to Firestore.
  Future<void> syncFullLocalProgressToRemote(String lessonId) async {
    final local = await _localProgressService.getLocalProgressForLesson(
      userId: _uid,
      lessonId: lessonId,
    );

    if (local == null) return;

    final docId = _progressDocId(lessonId);

    await _firestore.collection('progress').doc(docId).set({
      'progressId': docId,
      'userId': _uid,
      'lessonId': lessonId,
      'lessonCompleted': local.lessonCompleted,
      'practiceCompleted': local.practiceCompleted,
      'quizCompleted': local.quizCompleted,
      'videoViewed': local.videoViewed,
      'score': local.score,
      'videoPositionSeconds': local.videoPositionSeconds,
      'videoDurationSeconds': local.videoDurationSeconds,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> saveQuizProgress({
    required String lessonId,
    required int score,
  }) async {
    final existing = await getUserProgressForLesson(lessonId);
    final bestScore = score > (existing?.score ?? 0)
        ? score
        : (existing?.score ?? 0);

    await _localProgressService.saveLessonProgress(
      progressId: _progressDocId(lessonId),
      userId: _uid,
      lessonId: lessonId,
      quizCompleted: true,
      score: bestScore,
    );

    await refreshLocalProgressStream();
    await syncFullLocalProgressToRemote(lessonId);
  }

  Future<void> savePracticeProgress({required String lessonId}) async {
    await _localProgressService.saveLessonProgress(
      progressId: _progressDocId(lessonId),
      userId: _uid,
      lessonId: lessonId,
      practiceCompleted: true,
    );

    await refreshLocalProgressStream();
    await syncFullLocalProgressToRemote(lessonId);
  }

  Future<void> saveVideoProgress({
    required String lessonId,
    required int positionSeconds,
    required int durationSeconds,
    required bool videoViewed,
  }) async {
    await _localProgressService.saveLessonProgress(
      progressId: _progressDocId(lessonId),
      userId: _uid,
      lessonId: lessonId,
      videoViewed: videoViewed,
      videoPositionSeconds: positionSeconds,
      videoDurationSeconds: durationSeconds,
    );

    await refreshLocalProgressStream();
    await syncFullLocalProgressToRemote(lessonId);
  }

  Future<void> updateLessonCompleted({required String lessonId}) async {
    await refreshLocalProgressStream();
    await syncFullLocalProgressToRemote(lessonId);
  }

  Future<void> markVideoViewed(String docId) async {
    final lessonId = docId.replaceFirst('${_uid}_', '');
    await saveVideoProgress(
      lessonId: lessonId,
      positionSeconds: 0,
      durationSeconds: 0,
      videoViewed: true,
    );
  }

  Future<void> markQuizCompleted(String docId, int score) async {
    final lessonId = docId.replaceFirst('${_uid}_', '');
    await saveQuizProgress(lessonId: lessonId, score: score);
  }

  Future<void> markPracticeCompleted(String docId) async {
    final lessonId = docId.replaceFirst('${_uid}_', '');
    await savePracticeProgress(lessonId: lessonId);
  }

  Future<void> markLessonCompleted(String docId) async {
    final lessonId = docId.replaceFirst('${_uid}_', '');
    await syncFullLocalProgressToRemote(lessonId);
  }

  void dispose() {
    _progressController.close();
  }
}
