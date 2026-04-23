import 'package:flutter/material.dart';
import '../models/lesson.dart';
import 'quiz_screen.dart';

// This screen shows the details of one selected lesson.
class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    // This checks whether the current lesson is locked.
    final bool isLocked = lesson.isLocked;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,

        // This back button returns the user to the previous screen.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,

        // This shows the lesson number and title in the app bar.
        title: Text(
          'Laccar ${lesson.number}: ${lesson.title}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // This top section looks like a tab area for Video, Quiz, and Practice.
          // For now, only the Video tab is active in this screen.
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 14, left: 22, right: 22),
            child: Column(
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LessonTab(title: 'Video', isActive: true),
                    _LessonTab(title: 'Jaraba', isActive: false),
                    _LessonTab(title: 'Aiki', isActive: false),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // This is the video placeholder area.
                    // A real video player can be added here later.
                    Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 70,
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 14,
                            child: Text(
                              lesson.durationText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // This heading introduces the short lesson summary.
                    const Text(
                      'A takaice:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // This shows the lesson summary text.
                    Text(
                      lesson.summary,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // This button starts the quiz if the lesson is not locked.
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLocked
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QuizScreen(lesson: lesson),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLocked
                              ? Colors.grey
                              : const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isLocked ? 'A Kulle' : 'Fara Jaraba',
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

// This small widget is used to display the tab labels at the top.
class _LessonTab extends StatelessWidget {
  final String title;
  final bool isActive;

  const _LessonTab({required this.title, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF2D8CE0) : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),

        // This line under the text shows which tab is active.
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2D8CE0) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
