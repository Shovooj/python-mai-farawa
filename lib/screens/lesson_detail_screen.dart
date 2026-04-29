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
  final ProgressSyncService _progressSyncService = ProgressSyncService();
  final LocalLessonContentService localLessonContentService =
      LocalLessonContentService();
  final FirestoreService firestoreService = FirestoreService();
  final LocalVideoService _localVideoService = LocalVideoService();

  bool _isDownloadingVideo = false;
  bool _isVideoAvailableOffline = false;
  String? _localVideoPath;

  int _lastSavedSecond = 0;
  bool _isSavingVideoProgress = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<String> _getUid() async {
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
                  'questionText': q.questionText,
                  'optionA': q.optionA,
                  'optionB': q.optionB,
                  'optionC': q.optionC,
                  'optionD': q.optionD,
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
          instruction: practice.instruction,
          starterCode: practice.starterCode,
          expectedOutput: practice.expectedOutput,
          order: practice.order,
        );
      }
    } catch (e) {
      debugPrint('Offline content cache failed: $e');
    }
  }

  Future<void> _saveInitialLocalProgress() async {
    final uid = await _getUid();

    final existing = await _getExistingLocalProgress(uid);

    await _localProgressService.upsertLocalProgress(
      progressId: '${uid}_${widget.lesson.lessonId}',
      userId: uid,
      lessonId: widget.lesson.lessonId,
      lessonCompleted: existing?.lessonCompleted ?? false,
      practiceCompleted: existing?.practiceCompleted ?? false,
      quizCompleted: existing?.quizCompleted ?? false,
      videoViewed: existing?.videoViewed ?? false,
      score: existing?.score ?? 0,
      videoPositionSeconds: existing?.videoPositionSeconds ?? 0,
      videoDurationSeconds: existing?.videoDurationSeconds ?? 0,
    );
  }

  Future<ProgressModel?> _getExistingLocalProgress(String uid) async {
    final rows = await _localProgressService.getUserLocalProgress(uid);

    try {
      return rows.firstWhere((item) => item.lessonId == widget.lesson.lessonId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveVideoProgress() async {
    if (_isSavingVideoProgress) return;

    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    _isSavingVideoProgress = true;

    try {
      final uid = await _getUid();

      final positionSeconds = _videoController!.value.position.inSeconds;
      final durationSeconds = _videoController!.value.duration.inSeconds;

      bool viewed = false;
      if (durationSeconds > 0) {
        final watchedFraction = positionSeconds / durationSeconds;
        viewed = watchedFraction >= 0.9;
      }

      final existing = await _getExistingLocalProgress(uid);

      final quizCompleted = existing?.quizCompleted ?? false;
      final practiceCompleted = existing?.practiceCompleted ?? false;
      final score = existing?.score ?? 0;

      final lessonCompleted = quizCompleted && practiceCompleted && viewed;

      await _localProgressService.upsertLocalProgress(
        progressId: '${uid}_${widget.lesson.lessonId}',
        userId: uid,
        lessonId: widget.lesson.lessonId,
        lessonCompleted: lessonCompleted,
        practiceCompleted: practiceCompleted,
        quizCompleted: quizCompleted,
        videoViewed: viewed,
        score: score,
        videoPositionSeconds: positionSeconds,
        videoDurationSeconds: durationSeconds,
      );

      await _progressService.saveVideoProgress(
        lessonId: widget.lesson.lessonId,
        positionSeconds: positionSeconds,
        durationSeconds: durationSeconds,
        videoViewed: viewed,
      );

      await _progressService.updateLessonCompleted(
        lessonId: widget.lesson.lessonId,
      );

      try {
        await _progressSyncService.syncPendingProgress();
      } catch (_) {}
    } finally {
      _isSavingVideoProgress = false;
    }
  }

  void _videoListener() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final currentSecond = _videoController!.value.position.inSeconds;
    final durationSeconds = _videoController!.value.duration.inSeconds;

    if (durationSeconds > 0 && currentSecond >= durationSeconds) {
      _saveVideoProgress();
      return;
    }

    if (currentSecond > 0 &&
        currentSecond % 5 == 0 &&
        currentSecond != _lastSavedSecond) {
      _lastSavedSecond = currentSecond;
      _saveVideoProgress();
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
        _localVideoPath = localFile.path;
        _isVideoAvailableOffline = true;
        _videoController = VideoPlayerController.file(File(localFile.path));
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
      }

      await _videoController!.initialize();
      _videoController!.addListener(_videoListener);

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

  Future<void> _downloadVideoForOffline() async {
    final videoUrl = widget.lesson.videoUrl.trim();

    if (videoUrl.isEmpty) return;

    setState(() {
      _isDownloadingVideo = true;
    });

    try {
      final file = await _localVideoService.downloadVideo(
        lessonId: widget.lesson.lessonId,
        videoUrl: videoUrl,
      );

      _localVideoPath = file.path;
      _isVideoAvailableOffline = true;

      await _videoController?.dispose();

      _videoController = null;

      if (mounted) {
        setState(() {
          _isVideoReady = false;
          _hasVideoError = false;
        });
      }

      _videoController = VideoPlayerController.file(File(file.path));
      await _videoController!.initialize();
      _videoController!.addListener(_videoListener);

      if (!mounted) return;

      setState(() {
        _isVideoReady = true;
        _hasVideoError = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video downloaded for offline use.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Video download failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingVideo = false;
        });
      }
    }
  }

  Future<void> _openQuiz() async {
    if (!mounted) return;
    await cacheLessonContentForOffline();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(lesson: widget.lesson),
      ),
    );

    try {
      await _saveInitialLocalProgress();
    } catch (e) {
      debugPrint('Local progress save failed: $e');
    }

    try {
      await _progressSyncService.syncPendingProgress();
    } catch (e) {
      debugPrint('Progress sync failed: $e');
    }

    if (mounted) {
      setState(() {});
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
    _saveVideoProgress();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          'Lesson ${lesson.lessonNumber}: ${lesson.title}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          const LessonHeaderTabs(activeTab: 'video'),
          Expanded(
            child: SingleChildScrollView(
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
                                      ? 'Offline video not available'
                                      : 'Video not available. Download it while online for offline use.',
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
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.description,
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
                        onPressed: _openQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Start Quiz',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _isDownloadingVideo
                            ? null
                            : _downloadVideoForOffline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2D8CE0),
                          side: const BorderSide(
                            color: Color(0xFF2D8CE0),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: _isDownloadingVideo
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _isVideoAvailableOffline
                                    ? 'Video Downloaded for Offline Use'
                                    : 'Download Video for Offline Use',
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
        ],
      ),
    );
  }
}
