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
import 'package:provider/provider.dart';
import '../language_provider.dart';
import '../services/local_lesson_content_service.dart';

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

  Future<String> getUid(BuildContext context) async {
    final lang = context.read<LanguageProvider>().languageCode;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(AppStrings.text(lang, 'noSignedInUserFound'));
    }

    return user.uid;
  }

  Future<bool> ensurePracticeAvailableOffline(BuildContext context) async {
    final localLessonContentService = LocalLessonContentService();

    final localRows = await localLessonContentService.getPracticesByLessonId(
      lesson.lessonId,
    );

    debugPrint(
      'MOVE TO PRACTICE CHECK -> lessonId=${lesson.lessonId}, local practice count=${localRows.length}',
    );

    return localRows.isNotEmpty;
  }

  Future<void> saveQuizProgressOfflineFirst(BuildContext context) async {
    final uid = await getUid(context);

    final localProgressService = LocalProgressService();
    final progressSyncService = ProgressSyncService();
    final progressService = ProgressService();
    final syncQueueService = SyncQueueService();

    final rows = await localProgressService.getUserLocalProgress(uid);

    ProgressModel? existing;
    try {
      existing = rows.firstWhere((item) => item.lessonId == lesson.lessonId);
    } catch (_) {
      existing = null;
    }

    // Only update the quiz-specific fields locally and remotely. Do NOT
    // compute or send lessonCompleted here — LocalProgressService is the
    // single source of truth for merging and computing lessonCompleted.
    const bool quizCompleted = true;
    final int bestScore = score > (existing?.score ?? 0)
        ? score
        : (existing?.score ?? 0);

    final progressId = '${uid}_${lesson.lessonId}';

    await localProgressService.saveLessonProgress(
      progressId: progressId,
      userId: uid,
      lessonId: lesson.lessonId,
      quizCompleted: quizCompleted,
      score: bestScore,
    );

    await progressService.refreshLocalProgressStream();
    final payload = {
      'progressId': progressId,
      'userId': uid,
      'lessonId': lesson.lessonId,
      'quizCompleted': 1,
      'score': bestScore,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await syncQueueService.addToQueue(
      entityType: 'progress',
      entityId: lesson.lessonId,
      operation: 'upsert',
      payload: payload,
    );

    if (await hasInternet()) {
      try {
        await progressService.syncFullLocalProgressToRemote(lesson.lessonId);
        await progressSyncService.syncPendingProgress();
      } catch (e) {
        debugPrint('Remote quiz progress sync failed: $e');
      }
    }

    final saved = await localProgressService.getLocalProgressForLesson(
      userId: uid,
      lessonId: lesson.lessonId,
    );

    debugPrint(
      'QUIZ RESULT SAVED -> '
      'quizCompleted=${saved?.quizCompleted}, '
      'practiceCompleted=${saved?.practiceCompleted}, '
      'videoViewed=${saved?.videoViewed}, '
      'lessonCompleted=${saved?.lessonCompleted}, '
      'score=${saved?.score}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final percentage = totalQuestions == 0
        ? 0
        : ((score / totalQuestions) * 100).round();
    final passMark = quiz.passingScore;
    final hasPassed = score >= passMark;

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
                            debugPrint(
                              'MOVE TO PRACTICE TAP -> start, lessonId=${lesson.lessonId}',
                            );

                            try {
                              await saveQuizProgressOfflineFirst(context);
                            } catch (e, st) {
                              debugPrint('MOVE TO PRACTICE -> save failed: $e');
                              debugPrint('$st');
                            }

                            if (!context.mounted) return;

                            if (hasPassed) {
                              final hasLocalPractice =
                                  await ensurePracticeAvailableOffline(context);

                              if (!context.mounted) return;

                              if (!hasLocalPractice) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Practice content is not available offline for this lesson yet. Please re-download this lesson while online.',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            try {
                              await Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => hasPassed
                                      ? PracticeScreen(lesson: lesson)
                                      : QuizScreen(lesson: lesson),
                                ),
                              );
                            } catch (e, st) {
                              debugPrint(
                                'MOVE TO PRACTICE -> navigation failed: $e',
                              );
                              debugPrint('$st');
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
