import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/lesson_model.dart';
import '../models/practice_model.dart';
import '../models/progress_model.dart';
import '../services/firestore_service.dart';
import '../services/local_lesson_content_service.dart';
import '../services/local_progress_service.dart';
import '../services/progress_service.dart';
import '../services/progress_sync_service.dart';
import 'lesson_detail_screen.dart';
import 'lesson_header_tabs.dart';
import '../localization/app_strings.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

class PracticeScreen extends StatefulWidget {
  final Lesson lesson;

  const PracticeScreen({super.key, required this.lesson});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late Future<List<PracticeModel>> _practicesFuture;
  final FirestoreService firestoreService = FirestoreService();
  final LocalLessonContentService localLessonContentService =
      LocalLessonContentService();
  final LocalProgressService localProgressService = LocalProgressService();
  final ProgressService progressService = ProgressService();
  final ProgressSyncService progressSyncService = ProgressSyncService();

  WebViewController? webViewController;
  bool webViewReady = false;
  bool starterLoaded = false;
  bool practiceCompleted = false;

  final TextEditingController codeController = TextEditingController();

  String output = '';
  bool isRunning = false;

  String _initialStarterCode = '';
  String _currentPracticeId = '';

  @override
  void initState() {
    super.initState();
    _practicesFuture = loadPractices();
    _loadExistingPracticeCompletion();
    initializeSkulptRunner();
  }

  Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<String> getUid() async {
    final lang = context.read<LanguageProvider>().languageCode;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception(AppStrings.text(lang, 'noSignedInUserFound'));
    }
    return user.uid;
  }

  Future<void> initializeSkulptRunner() async {
    final lang = context.read<LanguageProvider>().languageCode;

    try {
      if (mounted) {
        setState(() {
          webViewReady = false;
          output = AppStrings.text(lang, 'loadingPythonRunner');
        });
      }

      final htmlString = await rootBundle.loadString(
        'assets/skulpt_runner.html',
      );

      webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..addJavaScriptChannel(
          'RunnerChannel',
          onMessageReceived: (JavaScriptMessage message) {
            try {
              final data = jsonDecode(message.message) as Map<String, dynamic>;
              final type = (data['type'] ?? '').toString();
              final messageOutput = (data['output'] ?? '').toString();

              if (!mounted) return;

              setState(() {
                if (type == 'ready') {
                  webViewReady = true;
                  output = messageOutput;
                  isRunning = false;
                } else if (type == 'success') {
                  isRunning = false;
                  output = messageOutput.trim().isEmpty
                      ? AppStrings.text(
                          lang,
                          'codeExecutedSuccessfullyWithNoOutput',
                        )
                      : messageOutput;
                } else if (type == 'error') {
                  isRunning = false;
                  output = messageOutput;
                }
              });
            } catch (e) {
              if (!mounted) return;
              setState(() {
                isRunning = false;
                output =
                    '${AppStrings.text(lang, 'failedToReadRunnerResponse')}: $e';
              });
            }
          },
        )
        ..loadHtmlString(htmlString);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        webViewReady = false;
        output =
            '${AppStrings.text(lang, 'failedToInitializePythonRunner')}: $e';
      });
    }
  }

  Future<void> _loadExistingPracticeCompletion() async {
    try {
      final uid = await getUid();
      final existingRows = await localProgressService.getUserLocalProgress(uid);

      ProgressModel? existing;
      try {
        existing = existingRows.firstWhere(
          (item) => item.lessonId == widget.lesson.lessonId,
        );
      } catch (_) {
        existing = null;
      }

      if (!mounted) return;

      setState(() {
        practiceCompleted = existing?.practiceCompleted ?? false;
      });
    } catch (e) {
      debugPrint('Failed to load existing practice completion: $e');
    }
  }

  Future<List<PracticeModel>> loadPractices() async {
    final lang = context.read<LanguageProvider>().languageCode;
    try {
      if (await hasInternet()) {
        final onlinePractices = await firestoreService.getPracticesByLessonId(
          widget.lesson.lessonId,
        );

        for (final practice in onlinePractices) {
          await localLessonContentService.cachePractice(
            practiceId: practice.practiceId,
            lessonId: practice.lessonId,
            title: practice.titleForLang(lang),
            instruction: practice.instructionForLang(lang),
            starterCode: practice.starterCode,
            expectedOutput: practice.expectedOutputForLang(lang),
            order: practice.order,
          );
        }

        if (onlinePractices.isNotEmpty) {
          return onlinePractices..sort((a, b) => a.order.compareTo(b.order));
        }
      }
    } catch (e) {
      debugPrint('Online practice load failed: $e');
    }

    try {
      final localRows = await localLessonContentService.getPracticesByLessonId(
        widget.lesson.lessonId,
      );

      final localPractices =
          localRows
              .map(
                (row) => PracticeModel(
                  practiceId: row['practiceId'] as String? ?? '',
                  lessonId: row['lessonId'] as String? ?? '',
                  title: row['title'] as String? ?? '',
                  instruction: row['instruction'] as String? ?? '',
                  starterCode: row['starterCode'] as String? ?? '',
                  expectedOutput: row['expectedOutput'] as String? ?? '',
                  order:
                      (row['practiceOrder'] as int?) ??
                      (row['order'] as int?) ??
                      0,
                  titleHa: row['titleHa'] as String? ?? '',
                  instructionHa: row['instructionHa'] as String? ?? '',
                  expectedOutputHa: row['expectedOutputHa'] as String? ?? '',
                ),
              )
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

      return localPractices;
    } catch (e) {
      debugPrint('Local practice load failed: $e');
      rethrow;
    }
  }

  Future<void> runCode() async {
    final lang = context.read<LanguageProvider>().languageCode;

    if (!webViewReady) {
      setState(() {
        output = AppStrings.text(lang, 'pythonRunnerStillLoading');
      });
      return;
    }

    final code = codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        output = AppStrings.text(lang, 'pleaseWritePythonCodeBeforeRun');
      });
      return;
    }

    setState(() {
      isRunning = true;
      output = AppStrings.text(lang, 'runningCode');
    });

    try {
      final escapedCode = jsonEncode(code);
      if (webViewController == null) {
        setState(() {
          isRunning = false;
          output = AppStrings.text(lang, 'pythonRunnerNotReadyYet');
        });
        return;
      }

      await webViewController!.runJavaScript('runPython($escapedCode);');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isRunning = false;
        output = '${AppStrings.text(lang, 'failedToRunCode')}: $e';
      });
    }
  }

  void clearCode() {
    final lang = context.read<LanguageProvider>().languageCode;

    setState(() {
      codeController.clear();
      output = AppStrings.text(lang, 'yourCodeHasBeenCleared');
    });
  }

  void resetCode() {
    final lang = context.read<LanguageProvider>().languageCode;

    setState(() {
      codeController.text = _initialStarterCode;
      output = AppStrings.text(lang, 'starterCodeRestored');
    });
  }

  Future<void> markPracticeCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final existingRows = await localProgressService.getUserLocalProgress(uid);

    ProgressModel? existing;
    try {
      existing = existingRows.firstWhere(
        (item) => item.lessonId == widget.lesson.lessonId,
      );
    } catch (_) {
      existing = null;
    }

    const bool completedPractice = true;
    final bool quizCompleted = existing?.quizCompleted ?? false;
    final bool videoViewed = existing?.videoViewed ?? false;
    final int score = existing?.score ?? 0;
    final bool lessonCompleted =
        quizCompleted && completedPractice && videoViewed;

    await localProgressService.upsertLocalProgress(
      progressId: '${uid}_${widget.lesson.lessonId}',
      userId: uid,
      lessonId: widget.lesson.lessonId,
      lessonCompleted: lessonCompleted,
      practiceCompleted: completedPractice,
      quizCompleted: quizCompleted,
      videoViewed: videoViewed,
      score: score,
      videoPositionSeconds: existing?.videoPositionSeconds ?? 0,
      videoDurationSeconds: existing?.videoDurationSeconds ?? 0,
    );

    try {
      await progressService.savePracticeProgress(
        lessonId: widget.lesson.lessonId,
      );
      await progressService.updateLessonCompleted(
        lessonId: widget.lesson.lessonId,
      );
      await progressSyncService.syncPendingProgress();
    } catch (e) {
      debugPrint('Remote practice progress sync failed: $e');
    }

    if (!mounted) return;

    final lang = context.read<LanguageProvider>().languageCode;

    setState(() {
      practiceCompleted = true;
      output = AppStrings.text(lang, 'practiceTaskMarkedCompleted');
    });
  }

  Future<void> goToNextLesson() async {
    final nextLessonNumber = widget.lesson.lessonNumber + 1;

    try {
      final nextLesson = await firestoreService.getLessonByLessonNumber(
        nextLessonNumber,
      );

      if (!mounted) return;

      final lang = context.read<LanguageProvider>().languageCode;

      if (nextLesson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.text(lang, 'noNextLessonFound'))),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(lesson: nextLesson),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final lang = context.read<LanguageProvider>().languageCode;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.text(lang, 'couldNotOpenNextLessonOfflineYet'),
          ),
        ),
      );
      debugPrint('Failed to load next lesson: $e');
    }
  }

  Widget _buildCodeEditor() {
    final lang = context.read<LanguageProvider>().languageCode;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),

      child: TextField(
        controller: codeController,
        minLines: 12,
        maxLines: null,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.5,
          fontFamily: 'monospace',
        ),

        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: AppStrings.text(lang, 'writePythonCodeHere'),
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildOutputCard(PracticeModel practice) {
    final lang = context.read<LanguageProvider>().languageCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.text(lang, 'output'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(
              output,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${AppStrings.text(lang, 'expectedOutputPrefix')}: ${practice.expectedOutputForLang(lang)}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final lang = context.read<LanguageProvider>().languageCode;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: clearCode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D8CE0),
                    side: const BorderSide(color: Color(0xFF2D8CE0), width: 2),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    AppStrings.text(lang, 'clearCode'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: resetCode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade700, width: 2),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    AppStrings.text(lang, 'resetCode'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isRunning ? null : runCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isRunning
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppStrings.text(lang, 'runCode'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionButtons() {
    final lang = context.read<LanguageProvider>().languageCode;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: practiceCompleted ? null : markPracticeCompleted,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              practiceCompleted
                  ? AppStrings.text(lang, 'practiceCompleted')
                  : AppStrings.text(lang, 'markPracticeCompleted'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (practiceCompleted) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: goToNextLesson,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D8CE0),
                      side: const BorderSide(
                        color: Color(0xFF2D8CE0),
                        width: 2,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      AppStrings.text(lang, 'nextLesson'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D8CE0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      AppStrings.text(lang, 'goToHome'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    codeController.dispose();
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
          LessonHeaderTabs(
            activeTab: AppStrings.text(lang, 'activeTabPractice'),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: FutureBuilder<List<PracticeModel>>(
                future: _practicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${AppStrings.text(lang, 'errorLoadingPractice')}: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final practices = snapshot.data ?? [];

                  if (practices.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.text(lang, 'noPracticeFoundForThisLesson'),
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    );
                  }

                  final practice = practices.first;

                  if (_currentPracticeId != practice.practiceId) {
                    _currentPracticeId = practice.practiceId;
                    _initialStarterCode = practice.starterCode;
                    starterLoaded = false;
                  }

                  if (!starterLoaded) {
                    codeController.text = practice.starterCode;
                    _initialStarterCode = practice.starterCode;
                    starterLoaded = true;
                  }

                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      practice.titleForLang(lang),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      practice.instructionForLang(lang),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildCodeEditor(),
                              const SizedBox(height: 14),
                              _buildActionButtons(),
                              const SizedBox(height: 16),
                              _buildOutputCard(practice),
                              const SizedBox(height: 16),
                              _buildCompletionButtons(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      if (webViewController != null)
                        SizedBox(
                          height: 1,
                          width: 1,
                          child: WebViewWidget(controller: webViewController!),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
