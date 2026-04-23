import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../data/lesson_data.dart';
import 'lesson_detail_screen.dart';
import 'lesson_list_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

// This is the main dashboard screen of the app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // This gets the current shared lesson list from LessonData.
  List<Lesson> get lessons => LessonData.lessons;

  // This finds the next lesson the learner should continue with.
  // It checks for the first lesson that is not completed and not locked.
  Lesson? get currentLesson {
    for (final lesson in lessons) {
      if (!lesson.isCompleted && !lesson.isLocked) {
        return lesson;
      }
    }

    // If all lessons are completed or no open lesson is found,
    // return the first lesson if the list is not empty.
    if (lessons.isNotEmpty) {
      return lessons.first;
    }

    return null;
  }

  // This opens the lesson detail screen, then refreshes HomeScreen
  // when the user comes back.
  Future<void> _openLessonDetail(Lesson lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );

    setState(() {});
  }

  // This opens the lesson list screen, then refreshes HomeScreen after return.
  Future<void> _openLessonList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonListScreen(lessons: lessons),
      ),
    );

    setState(() {});
  }

  // This opens the progress screen, then refreshes HomeScreen after return.
  Future<void> _openProgressScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProgressScreen()),
    );

    setState(() {});
  }

  // This opens the settings screen, then refreshes HomeScreen after return.
  Future<void> _openSettingsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    setState(() {});
  }

  // This shows a message when the learner taps a locked lesson.
  void _showLockedLessonMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete the previous lessons before opening this one.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // These values are taken from the shared lesson data.
    final double progress = LessonData.progressPercent;
    final int completedLessons = LessonData.completedCount;
    final Lesson? lessonToContinue = currentLesson;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),

            // This is the circular app logo shown in the app bar.
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

            // This is the app title.
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
      body: Column(
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
                      // Greeting text for the learner.
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
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),

                      // This section shows the learner's progress bar and progress text.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% completed ($completedLessons/${lessons.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // This card helps the learner continue from the next available lesson.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: lessonToContinue == null
                            ? const Text(
                                'No lesson available right now.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              )
                            : Row(
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
                                          'Lesson ${lessonToContinue.number}: ${lessonToContinue.title}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // This play button opens the lesson to continue.
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

                      // This title introduces the lesson directory section.
                      const Text(
                        'Lessons',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // This grid shows all the lessons as cards.
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

                          return GestureDetector(
                            onTap: () {
                              // If the lesson is locked, show a warning message.
                              if (lesson.isLocked) {
                                _showLockedLessonMessage();
                                return;
                              }

                              // If the lesson is open, go to the lesson details.
                              _openLessonDetail(lesson);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lesson.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // This icon changes based on the lesson state.
                                  Icon(
                                    lesson.isCompleted
                                        ? Icons.check_circle
                                        : lesson.isLocked
                                        ? Icons.lock
                                        : Icons.lock_open,
                                    color: lesson.isCompleted
                                        ? Colors.green
                                        : lesson.isLocked
                                        ? Colors.black54
                                        : const Color(0xFF2D8CE0),
                                  ),
                                ],
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

          // This is the bottom navigation used to move to other main screens.
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
      ),
    );
  }
}
