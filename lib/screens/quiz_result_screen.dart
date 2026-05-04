import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../models/quiz_model.dart';
import '../services/local_progress_service.dart';
import '../services/progress_service.dart';
import '../services/progress_sync_service.dart';
import '../services/sync_queue_service.dart';
import 'lesson_header_tabs.dart';
import 'practice_screen.dart';
import 'quiz_screen.dart';
import '../localization/app_strings.dart';

final lang = 'en'; // temporary for now, until settings is connected

class QuizResultScreen extends StatelessWidget {
  final Lesson lesson;
  final QuizModel quiz;
  final int score;
  final int totalQuestions;

  const QuizResultScreen({
    super.key,
    required this.lesson,
    required this.quiz,
    required this.score,
    required this.totalQuestions,
  });

  Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<String> getUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      throw Exception(AppStrings.text(lang, 'noSignedInUserFound'));
    return user.uid;
  }

  Future<void> saveQuizProgressOfflineFirst() async {
    final uid = await getUid();
    final localProgressService = LocalProgressService();
    final progressSyncService = ProgressSyncService();
    final progressService = ProgressService();
    final syncQueueService = SyncQueueService();

    final List<ProgressModel> rows = await localProgressService
        .getUserLocalProgress(uid);

    ProgressModel? existing;
    try {
      existing = rows.firstWhere((item) => item.lessonId == lesson.lessonId);
    } catch (_) {
      existing = null;
    }

    final bool quizCompleted = true;
    final bool practiceCompleted = existing?.practiceCompleted ?? false;
    final bool videoViewed = existing?.videoViewed ?? false;
    final int bestScore = score > (existing?.score ?? 0)
        ? score
        : (existing?.score ?? 0);
    final int videoPositionSeconds = existing?.videoPositionSeconds ?? 0;
    final int videoDurationSeconds = existing?.videoDurationSeconds ?? 0;
    final bool lessonCompleted =
        quizCompleted && practiceCompleted && videoViewed;

    final payload = {
      'progressId': '$uid${lesson.lessonId}',
      'userId': uid,
      'lessonId': lesson.lessonId,
      'lessonCompleted': lessonCompleted ? 1 : 0,
      'practiceCompleted': practiceCompleted ? 1 : 0,
      'quizCompleted': quizCompleted ? 1 : 0,
      'videoViewed': videoViewed ? 1 : 0,
      'score': bestScore,
      'videoPositionSeconds': videoPositionSeconds,
      'videoDurationSeconds': videoDurationSeconds,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await localProgressService.upsertLocalProgress(
      progressId: payload['progressId'] as String,
      userId: payload['userId'] as String,
      lessonId: payload['lessonId'] as String,
      lessonCompleted: lessonCompleted,
      practiceCompleted: practiceCompleted,
      quizCompleted: quizCompleted,
      videoViewed: videoViewed,
      score: bestScore,
      videoPositionSeconds: videoPositionSeconds,
      videoDurationSeconds: videoDurationSeconds,
    );

    await syncQueueService.addToQueue(
      entityType: 'progress',
      entityId: lesson.lessonId,
      operation: 'upsert',
      payload: payload,
    );

    if (await hasInternet()) {
      await progressService.saveQuizProgress(
        lessonId: lesson.lessonId,
        score: bestScore,
      );
      await progressService.updateLessonCompleted(lessonId: lesson.lessonId);
      await progressSyncService.syncPendingProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = totalQuestions == 0
        ? 0
        : ((score / totalQuestions) * 100).round();
    final passMark = quiz.passingScore;
    final hasPassed = percentage >= passMark;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            '${AppStrings.text(lang, 'lesson')} ${lesson.lessonNumber}: ${lesson.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          LessonHeaderTabs(activeTab: AppStrings.text(lang, 'activeTabQuiz')),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasPassed
                            ? Icons.verified_rounded
                            : Icons.cancel_rounded,
                        size: 72,
                        color: hasPassed ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hasPassed
                            ? AppStrings.text(lang, 'youPassed')
                            : AppStrings.text(lang, 'youDidNotPass'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: hasPassed ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${AppStrings.text(lang, 'lesson')} ${lesson.lessonNumber}: ${lesson.title}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${AppStrings.text(lang, 'youScored')} $score ${AppStrings.text(lang, 'outOf')} $totalQuestions',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D8CE0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppStrings.text(lang, 'passMark')}: $passMark',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final progressService = ProgressService();
                            final localProgressService = LocalProgressService();
                            final progressSyncService = ProgressSyncService();
                            final user = FirebaseAuth.instance.currentUser;

                            if (user == null) return;

                            final uid = user.uid;
                            final existingRows = await localProgressService
                                .getUserLocalProgress(uid);

                            ProgressModel? existing;
                            try {
                              existing = existingRows.firstWhere(
                                (item) => item.lessonId == lesson.lessonId,
                              );
                            } catch (_) {
                              existing = null;
                            }

                            final bestScore = score > (existing?.score ?? 0)
                                ? score
                                : (existing?.score ?? 0);
                            final quizCompleted = true;
                            final practiceCompleted =
                                existing?.practiceCompleted ?? false;
                            final videoViewed = existing?.videoViewed ?? false;
                            final lessonCompleted =
                                quizCompleted &&
                                practiceCompleted &&
                                videoViewed;

                            await localProgressService.upsertLocalProgress(
                              progressId: '${uid}_${lesson.lessonId}',
                              userId: uid,
                              lessonId: lesson.lessonId,
                              lessonCompleted: lessonCompleted,
                              practiceCompleted: practiceCompleted,
                              quizCompleted: quizCompleted,
                              videoViewed: videoViewed,
                              score: bestScore,
                              videoPositionSeconds:
                                  existing?.videoPositionSeconds ?? 0,
                              videoDurationSeconds:
                                  existing?.videoDurationSeconds ?? 0,
                            );

                            try {
                              await progressService.saveQuizProgress(
                                lessonId: lesson.lessonId,
                                score: score,
                              );
                              await progressService.updateLessonCompleted(
                                lessonId: lesson.lessonId,
                              );
                              await progressSyncService.syncPendingProgress();
                            } catch (_) {}

                            if (!context.mounted) return;

                            if (hasPassed) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PracticeScreen(lesson: lesson),
                                ),
                              );
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizScreen(lesson: lesson),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasPassed
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2D8CE0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            hasPassed
                                ? AppStrings.text(lang, 'moveToPractice')
                                : AppStrings.text(lang, 'tryAgain'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
