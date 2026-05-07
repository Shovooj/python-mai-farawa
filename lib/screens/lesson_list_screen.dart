import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/offline_lesson_service.dart';
import 'lesson_detail_screen.dart';
import '../localization/app_strings.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';
import '../services/local_lesson_content_service.dart';
import '../services/firestore_service.dart';
import '../services/local_video_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  String getUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No signed-in user found.');
    }
    return user.uid;
  }

  late Future<List<Lesson>> _lessonsFuture;

  final LocalVideoService localVideoService = LocalVideoService();

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _loadLessons();
  }

  final FirestoreService _firestoreService = FirestoreService();
  final LocalLessonContentService _localLessonContentService =
      LocalLessonContentService();

  final Set<String> _downloadingLessonIds = {};
  final ProgressService _progressService = ProgressService();
  final OfflineLessonService _offlineLessonService = OfflineLessonService();
  String searchQuery = '';

  int _downloadStatusVersion = 0;

  Future<List<Lesson>> _loadLessons() async {
    try {
      await _offlineLessonService.cacheLessonsFromFirestore();
    } catch (e) {
      debugPrint('Lesson cache failed: $e');
    }

    final localLessonMaps = await _offlineLessonService.getLocalLessons();
    final localLessons = localLessonMaps
        .map((map) => Lesson.fromMap(map))
        .toList();

    if (localLessons.isNotEmpty) {
      return localLessons;
    }

    debugPrint('No local lessons found, falling back to Firestore.');

    try {
      final firestoreLessons = await _firestoreService.getPublishedLessons();
      return firestoreLessons;
    } catch (e) {
      debugPrint('Firestore fallback failed: $e');
      return [];
    }
  }

  List<Lesson> _filterLessons(List<Lesson> lessons, String lang) {
    if (searchQuery.trim().isEmpty) {
      return lessons;
    }

    final query = searchQuery.toLowerCase();

    return lessons.where((lesson) {
      final title = lesson.titleForLang(lang).toLowerCase();
      final description = lesson.descriptionForLang(lang).toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  Future<void> openLesson(Lesson lesson, bool completed) async {
    final lang = context.read<LanguageProvider>().languageCode;

    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.text(lang, 'lessonAlreadyCompleted')),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
    );
  }

  Future<void> downloadLesson(Lesson lesson) async {
    final lang = context.read<LanguageProvider>().languageCode;

    if (_downloadingLessonIds.contains(lesson.lessonId)) return;

    setState(() {
      _downloadingLessonIds.add(lesson.lessonId);
    });

    try {
      await _localLessonContentService.downloadLessonPackageFromFirestore(
        userId: getUid(),
        lessonId: lesson.lessonId,
      );

      final videoUrl = lesson.videoUrl.trim();
      if (videoUrl.isNotEmpty) {
        await localVideoService.downloadVideo(
          lessonId: lesson.lessonId,
          videoUrl: videoUrl,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${lesson.titleForLang(lang)} downloaded for offline use.',
          ),
        ),
      );

      setState(() {
        _downloadStatusVersion++;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download ${lesson.titleForLang(lang)}: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingLessonIds.remove(lesson.lessonId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.text(lang, 'lessons'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: AppStrings.text(lang, 'findALesson'),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.text(lang, 'allLessons'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Lesson>>(
                future: _lessonsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${AppStrings.text(lang, 'errorLoadingLessons')} ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final allLessons = (snapshot.data ?? [])
                    ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

                  final lessons = _filterLessons(allLessons, lang);

                  if (lessons.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.text(lang, 'noLessonsFound'),
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    );
                  }

                  return StreamBuilder<List<ProgressModel>>(
                    stream: _progressService.getUserProgressStream(),
                    builder: (context, progressSnapshot) {
                      if (progressSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (progressSnapshot.hasError) {
                        return Center(
                          child: Text(
                            '${AppStrings.text(lang, 'errorLoadingProgress')} ${progressSnapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final progressList = progressSnapshot.data ?? [];

                      final Map<String, ProgressModel> progressMap = {
                        for (final progress in progressList)
                          progress.lessonId: progress,
                      };

                      bool isLessonUnlocked(Lesson lesson) {
                        final sortedIndex = allLessons.indexWhere(
                          (item) => item.lessonId == lesson.lessonId,
                        );

                        if (sortedIndex <= 0) return true;

                        final previousLesson = allLessons[sortedIndex - 1];
                        final previousProgress =
                            progressMap[previousLesson.lessonId];

                        return previousProgress?.lessonCompleted == true;
                      }

                      final uid = getUid();
                      return ListView.separated(
                        itemCount: lessons.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          final unlocked = isLessonUnlocked(lesson);
                          final completed =
                              progressMap[lesson.lessonId]?.lessonCompleted ==
                              true;

                          final isDownloading = _downloadingLessonIds.contains(
                            lesson.lessonId,
                          );

                          return GestureDetector(
                            onTap: unlocked
                                ? () => openLesson(lesson, completed)
                                : null,
                            child: Opacity(
                              opacity: unlocked ? 1.0 : 0.6,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(
                                        0xFF2D8CE0,
                                      ).withValues(alpha: 0.12),
                                      child: Text(
                                        '${lesson.lessonNumber}',
                                        style: const TextStyle(
                                          color: Color(0xFF2D8CE0),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        lesson.titleForLang(lang),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    if (completed)
                                      const Icon(
                                        Icons.check_circle,
                                        size: 20,
                                        color: Colors.green,
                                      )
                                    else if (unlocked)
                                      FutureBuilder<bool>(
                                        future: _localLessonContentService
                                            .isLessonPackageDownloaded(
                                              userId: uid,
                                              lessonId: lesson.lessonId,
                                            ),
                                        key: ValueKey(
                                          '${lesson.lessonId}_$_downloadStatusVersion',
                                        ),
                                        builder: (context, downloadSnapshot) {
                                          final isDownloaded =
                                              downloadSnapshot.data ?? false;

                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(width: 4),
                                              if (isDownloading)
                                                const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.4,
                                                      ),
                                                )
                                              else if (isDownloaded)
                                                const Icon(
                                                  Icons.download_done_rounded,
                                                  size: 22,
                                                  color: Colors.green,
                                                )
                                              else
                                                IconButton(
                                                  onPressed: () =>
                                                      downloadLesson(lesson),
                                                  icon: const Icon(
                                                    Icons.download_rounded,
                                                    color: Color(0xFF2D8CE0),
                                                    size: 22,
                                                  ),
                                                  tooltip: 'Download lesson',
                                                  constraints: BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.lock_open_rounded,
                                                size: 20,
                                                color: Color(0xFF2D8CE0),
                                              ),
                                            ],
                                          );
                                        },
                                      )
                                    else
                                      const Icon(
                                        Icons.lock,
                                        size: 20,
                                        color: Color(0xFF2D8CE0),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
