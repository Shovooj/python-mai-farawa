import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../services/local_progress_service.dart';
import '../services/progress_service.dart';
import '../services/progress_sync_service.dart';
import 'lesson_header_tabs.dart';
import 'quiz_screen.dart';
import 'dart:io';
import '../services/local_video_service.dart';
import '../services/local_lesson_content_service.dart';
import '../services/firestore_service.dart';
import '../localization/app_strings.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import 'home_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _hasVideoError = false;

  final ProgressService _progressService = ProgressService();
  final LocalProgressService _localProgressService = LocalProgressService();
  final ProgressSyncService progressSyncService = ProgressSyncService();
  final LocalLessonContentService localLessonContentService =
      LocalLessonContentService();
  final FirestoreService firestoreService = FirestoreService();
  final LocalVideoService _localVideoService = LocalVideoService();

  bool _isVideoAvailableOffline = false;

  int _lastSavedSecond = 0;
  bool _isSavingVideoProgress = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  String getUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No signed-in user found.');
    }
    return user.uid;
  }

  Future<void> cacheLessonContentForOffline() async {
    try {
      final quiz = await FirestoreService().getQuizByLessonId(
        widget.lesson.lessonId,
      );

      if (quiz != null) {
        await localLessonContentService.cacheQuiz(
          quizId: quiz.quizId,
          lessonId: quiz.lessonId,
          title: quiz.title,
          titleHa: quiz.titleHa,
          passingScore: quiz.passingScore,
          totalQuestions: quiz.totalQuestions,
        );

        final questionStream = await firestoreService.getQuestionsByQuizId(
          quiz.quizId,
        );
        final questions = await questionStream.first;

        await localLessonContentService.cacheQuestions(
          quiz.quizId,
          questions
              .map(
                (q) => {
                  'questionId': q.questionId,
                  'quizId': q.quizId,
                  'lessonId': q.lessonId,
                  'questionText': q.questionText,
                  'optionA': q.optionA,
                  'optionB': q.optionB,
                  'optionC': q.optionC,
                  'optionD': q.optionD,
                  'questionTextHa': q.questionTextHa,
                  'optionAHa': q.optionAHa,
                  'optionBHa': q.optionBHa,
                  'optionCHa': q.optionCHa,
                  'optionDHa': q.optionDHa,
                  'correctAnswer': q.correctAnswer,
                  'order': q.order,
                },
              )
              .toList(),
        );
      }

      final practices = await firestoreService.getPracticesByLessonId(
        widget.lesson.lessonId,
      );

      for (final practice in practices) {
        await localLessonContentService.cachePractice(
          practiceId: practice.practiceId,
          lessonId: practice.lessonId,
          title: practice.title,
          titleHa: practice.titleHa,
          instruction: practice.instruction,
          instructionHa: practice.instructionHa,
          starterCode: practice.starterCode,
          expectedOutput: practice.expectedOutput,
          expectedOutputHa: practice.expectedOutputHa,
          order: practice.order,
        );
      }
    } catch (e) {
      debugPrint('Offline content cache failed: $e');
    }
  }

  Future<void> saveInitialLocalProgress() async {
    final uid = getUid();

    final existing = await _getExistingLocalProgress(uid);

    await _localProgressService.saveLessonProgress(
      progressId: '${uid}_${widget.lesson.lessonId}',
      userId: uid,
      lessonId: widget.lesson.lessonId,
      videoViewed: existing?.videoViewed ?? false,
      score: existing?.score ?? 0,
      videoPositionSeconds: existing?.videoPositionSeconds ?? 0,
      videoDurationSeconds: existing?.videoDurationSeconds ?? 0,
    );

    await _progressService.refreshLocalProgressStream();
    await _progressService.refreshLocalProgress();
  }

  Future<ProgressModel?> _getExistingLocalProgress(String uid) async {
    return _localProgressService.getLocalProgressForLesson(
      userId: uid,
      lessonId: widget.lesson.lessonId,
    );
  }

  Future<void> debugPrintLocalLessonProgress() async {
    final uid = getUid();
    final rows = await _localProgressService.getUserLocalProgress(uid);

    try {
      final progress = rows.firstWhere(
        (item) => item.lessonId == widget.lesson.lessonId,
      );

      debugPrint('LOCAL PROGRESS FOR ${widget.lesson.lessonId}');
      debugPrint('videoViewed: ${progress.videoViewed}');
      debugPrint('practiceCompleted: ${progress.practiceCompleted}');
      debugPrint('quizCompleted: ${progress.quizCompleted}');
      debugPrint('lessonCompleted: ${progress.lessonCompleted}');
      debugPrint('score: ${progress.score}');
      debugPrint('videoPositionSeconds: ${progress.videoPositionSeconds}');
      debugPrint('videoDurationSeconds: ${progress.videoDurationSeconds}');
    } catch (_) {
      debugPrint('No local progress row found for ${widget.lesson.lessonId}');
    }
  }

  Future<void> saveVideoProgress({bool forceComplete = false}) async {
    if (_isSavingVideoProgress) return;
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    _isSavingVideoProgress = true;

    try {
      final positionSeconds = _videoController!.value.position.inSeconds;
      final durationSeconds = _videoController!.value.duration.inSeconds;

      bool viewed = false;
      if (durationSeconds > 0) {
        viewed = (positionSeconds / durationSeconds) >= 0.8;
      }
      if (forceComplete && durationSeconds > 0) viewed = true;

      // ONE write path only — ProgressService calls LocalProgressService
      // which OR-merges and refreshes the stream. No direct local write here.
      await _progressService.saveVideoProgress(
        lessonId: widget.lesson.lessonId,
        positionSeconds: positionSeconds,
        durationSeconds: durationSeconds,
        videoViewed: viewed,
      );

      // Read back for logging only
      final uid = getUid();
      final saved = await _localProgressService.getLocalProgressForLesson(
        userId: uid,
        lessonId: widget.lesson.lessonId,
      );
      debugPrint(
        'VIDEO LOCAL SAVE -> '
        'lessonId=${widget.lesson.lessonId}, '
        'quizCompleted=${saved?.quizCompleted}, '
        'practiceCompleted=${saved?.practiceCompleted}, '
        'videoViewed=${saved?.videoViewed}, '
        'lessonCompleted=${saved?.lessonCompleted}, '
        'score=${saved?.score}',
      );
    } catch (e) {
      debugPrint('saveVideoProgress failed: $e');
    } finally {
      _isSavingVideoProgress = false;
    }
  }

  void videoListener() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final currentSecond = _videoController!.value.position.inSeconds;
    final durationSeconds = _videoController!.value.duration.inSeconds;

    if (durationSeconds > 0) {
      final watchedFraction = currentSecond / durationSeconds;

      if (watchedFraction >= 0.8) {
        saveVideoProgress(forceComplete: true);
        return;
      }
    }

    if (currentSecond > 0 &&
        currentSecond % 5 == 0 &&
        currentSecond != _lastSavedSecond) {
      _lastSavedSecond = currentSecond;
      saveVideoProgress();
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.lesson.videoUrl.trim();

    if (videoUrl.isEmpty) {
      setState(() {
        _hasVideoError = true;
      });
      return;
    }

    try {
      final localFile = await _localVideoService.getDownloadedVideoFile(
        widget.lesson.lessonId,
      );

      if (localFile != null) {
        _isVideoAvailableOffline = true;
        _videoController = VideoPlayerController.file(File(localFile.path));
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
      }

      await _videoController!.initialize();
      _videoController!.addListener(videoListener);

      setState(() {
        _isVideoReady = true;
        _hasVideoError = false;
      });
    } catch (e) {
      setState(() {
        _hasVideoError = true;
      });
    }
  }

  Future<void> openQuiz() async {
    try {
      final hasPackage = await localLessonContentService
          .hasCompleteLessonPackage(
            userId: getUid(),
            lessonId: widget.lesson.lessonId,
          );

      if (!hasPackage) {
        await cacheLessonContentForOffline();
      }

      final hasValidatedPackage = await localLessonContentService
          .hasCompleteLessonPackage(
            userId: getUid(),
            lessonId: widget.lesson.lessonId,
          );

      if (!hasValidatedPackage) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lesson content is not available yet. Please connect to the internet and download this lesson again.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(lesson: widget.lesson),
        ),
      );

      await saveInitialLocalProgress();
      await progressSyncService.syncPendingProgress();

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open quiz: $e')));
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  @override
  void dispose() {
    // Remove the listener first so no more saves fire during teardown.
    _videoController?.removeListener(videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final lesson = widget.lesson;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        titleSpacing: 0,
        title: Text(
          '${AppStrings.text(lang, 'lesson')} '
          '${lesson.lessonNumber}: '
          '${lesson.titleForLang(lang)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          LessonHeaderTabs(activeTab: AppStrings.text(lang, 'activeTabVideo')),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _hasVideoError
                            ? Container(
                                height: 220,
                                alignment: Alignment.center,
                                color: Colors.black,
                                child: Text(
                                  _isVideoAvailableOffline
                                      ? AppStrings.text(
                                          lang,
                                          'offlineVideoNotAvailable',
                                        )
                                      : AppStrings.text(
                                          lang,
                                          'videoNotAvailableDownloadOnline',
                                        ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : !_isVideoReady || _videoController == null
                            ? Container(
                                height: 220,
                                alignment: Alignment.center,
                                color: Colors.black,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio:
                                        _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                      child: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 38,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.text(lang, 'description'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.descriptionForLang(lang),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: openQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          AppStrings.text(lang, 'startQuiz'),
                          style: TextStyle(
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
        ],
      ),
    );
  }
}
