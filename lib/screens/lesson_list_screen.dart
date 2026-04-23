import 'package:flutter/material.dart';
import '../models/lesson.dart';
import 'lesson_detail_screen.dart';

// This screen displays all lessons in a list format.
// It also allows the user to search for lessons by title or subtitle.
class LessonListScreen extends StatefulWidget {
  // The list of lessons passed from the previous screen.
  final List<Lesson> lessons;

  const LessonListScreen({super.key, required this.lessons});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  // Stores the current search text typed by the user.
  String searchQuery = '';

  // Returns the lessons that match the search query.
  // If the search box is empty, all lessons are shown.
  List<Lesson> get filteredLessons {
    if (searchQuery.trim().isEmpty) {
      return widget.lessons;
    }

    final query = searchQuery.toLowerCase();

    return widget.lessons.where((lesson) {
      return lesson.title.toLowerCase().contains(query) ||
          lesson.subtitle.toLowerCase().contains(query);
    }).toList();
  }

  // Opens the selected lesson if it is unlocked.
  // If the lesson is locked, a message is shown instead.
  Future<void> _openLesson(Lesson lesson) async {
    if (lesson.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kammala laccocin da suka gabata kafin buɗe wannan.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );

    // Refresh the screen when returning from lesson detail
    // so any progress or lesson changes are displayed immediately.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // The list to display depends on whether the user searched or not.
    final lessons = filteredLessons;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            // Returns to the previous screen.
            Navigator.pop(context, true);
          },
        ),
        title: const Text(
          'Darakta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search box for finding lessons by title or subtitle.
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    // Update the search query whenever the user types.
                    searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Nemi laccar',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section heading for all available lessons.
            const Text(
              'Duk Daraktoci',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: lessons.isEmpty
                  ? const Center(
                      // Message shown when no lesson matches the search.
                      child: Text(
                        'Ba a sami lacca ba.',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    )
                  : ListView.separated(
                      itemCount: lessons.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];

                        // Chooses the correct icon based on lesson state.
                        Icon trailingIcon;
                        if (lesson.isCompleted) {
                          trailingIcon = const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          );
                        } else if (lesson.isLocked) {
                          trailingIcon = const Icon(
                            Icons.lock,
                            color: Colors.black54,
                          );
                        } else {
                          trailingIcon = const Icon(
                            Icons.lock_open,
                            color: Color(0xFF2D8CE0),
                          );
                        }

                        return GestureDetector(
                          onTap: () => _openLesson(lesson),
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Lesson title
                                      Text(
                                        lesson.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Lesson subtitle and duration
                                      Text(
                                        '${lesson.subtitle} - ${lesson.durationText}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Completion / lock / unlocked state icon
                                trailingIcon,
                              ],
                            ),
                          ),
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
