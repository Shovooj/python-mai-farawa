import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';
import 'lesson_detail_screen.dart';
import 'lesson_list_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ProgressService _progressService = ProgressService();

  Future<void> _openLessonDetail(Lesson lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }

  Future<void> _openLessonList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LessonListScreen()),
    );
  }

  Future<void> _openProgressScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProgressScreen()),
    );
  }

  Future<void> _openSettingsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF4D24D),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D8CE0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Python Mai Farawa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _firestoreService.getPublishedLessons(),
        builder: (context, lessonSnapshot) {
          if (lessonSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (lessonSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading lessons: ${lessonSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final lessons =
              (lessonSnapshot.data ?? [])
                  .where((lesson) => lesson.lessonNumber > 0)
                  .toList()
                ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

          if (lessons.isEmpty) {
            return const Center(
              child: Text(
                'No lessons available right now.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            );
          }

          return StreamBuilder<List<ProgressModel>>(
            stream: _progressService.getUserProgressStream(),
            builder: (context, progressSnapshot) {
              if (progressSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (progressSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error loading progress: ${progressSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final progressList = progressSnapshot.data ?? [];

              //debug
              debugPrint('----- HOME DEBUG START -----');
              debugPrint('Lessons count: ${lessons.length}');
              for (final lesson in lessons) {
                debugPrint(
                  'Lesson -> title: ${lesson.title}, lessonNumber: ${lesson.lessonNumber}, lessonId: ${lesson.lessonId}',
                );
              }

              debugPrint('Progress count: ${progressList.length}');
              for (final progress in progressList) {
                debugPrint(
                  'Progress -> lessonId: ${progress.lessonId}, completed: ${progress.lessonCompleted}, quizCompleted: ${progress.quizCompleted}, practiceCompleted: ${progress.practiceCompleted}, videoViewed: ${progress.videoViewed}',
                );
              }
              debugPrint('----- HOME DEBUG END -----');

              final Map<String, ProgressModel> progressMap = {
                for (final progress in progressList)
                  progress.lessonId: progress,
              };

              debugPrint(
                'Progress map keys final: ${progressMap.keys.toList()}',
              );
              for (final lesson in lessons) {
                debugPrint(
                  'Match check -> lesson.lessonId: ${lesson.lessonId}, foundInProgressMap: ${progressMap.containsKey(lesson.lessonId)}',
                );
              }

              bool isLessonUnlocked(Lesson lesson, int index) {
                if (index == 0) return true;

                final previousLesson = lessons[index - 1];
                final previousProgress = progressMap[previousLesson.lessonId];

                return previousProgress?.lessonCompleted == true;
              }

              final completedLessons = lessons.where((lesson) {
                final progress = progressMap[lesson.lessonId];
                return progress?.lessonCompleted == true;
              }).length;

              final double overallProgress = lessons.isEmpty
                  ? 0.0
                  : completedLessons / lessons.length;

              Lesson lessonToContinue = lessons.first;

              for (int i = 0; i < lessons.length; i++) {
                if (isLessonUnlocked(lessons[i], i)) {
                  final currentProgress = progressMap[lessons[i].lessonId];
                  if (currentProgress?.lessonCompleted != true) {
                    lessonToContinue = lessons[i];
                    break;
                  }
                }
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        color: const Color(0xFFF5F5F5),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hello, Learner!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Track your learning',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: overallProgress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(overallProgress * 100).toStringAsFixed(0)}% completed ($completedLessons/${lessons.length})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(40, 0, 0, 0),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Continue Learning',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Lesson ${lessonToContinue.lessonNumber}: ${lessonToContinue.title}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _openLessonDetail(lessonToContinue),
                                      child: Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8F2FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Color(0xFF2D8CE0),
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Lessons',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 1.3,
                                    ),
                                itemCount: lessons.length,
                                itemBuilder: (context, index) {
                                  final lesson = lessons[index];
                                  final unlocked = isLessonUnlocked(
                                    lesson,
                                    index,
                                  );
                                  final lessonProgress =
                                      progressMap[lesson.lessonId];
                                  final completed =
                                      lessonProgress?.lessonCompleted == true;

                                  return GestureDetector(
                                    onTap: unlocked
                                        ? () => _openLessonDetail(lesson)
                                        : null,
                                    child: Opacity(
                                      opacity: unlocked ? 1.0 : 0.6,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lesson.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Lesson ${lesson.lessonNumber}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Icon(
                                                completed
                                                    ? Icons.check_circle
                                                    : unlocked
                                                    ? Icons.lock_open
                                                    : Icons.lock,
                                                color: completed
                                                    ? Colors.green
                                                    : const Color(0xFF2D8CE0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      currentIndex: 0,
                      selectedItemColor: const Color(0xFF2D8CE0),
                      unselectedItemColor: Colors.grey,
                      showUnselectedLabels: true,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home_rounded),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.menu_book_rounded),
                          label: 'Lessons',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.bar_chart_rounded),
                          label: 'Progress',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.settings_rounded),
                          label: 'Settings',
                        ),
                      ],
                      onTap: (index) {
                        if (index == 1) {
                          _openLessonList();
                        } else if (index == 2) {
                          _openProgressScreen();
                        } else if (index == 3) {
                          _openSettingsScreen();
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
