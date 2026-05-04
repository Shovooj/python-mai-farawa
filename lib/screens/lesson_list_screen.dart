import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/offline_lesson_service.dart';
import 'lesson_detail_screen.dart';
import '../localization/app_strings.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

final lang = 'en'; // temporary for now, until settings is connected

class _LessonListScreenState extends State<LessonListScreen> {
  final OfflineLessonService _offlineLessonService = OfflineLessonService();
  String searchQuery = '';

  Future<List<Lesson>> _loadLessons() async {
    try {
      await _offlineLessonService.cacheLessonsFromFirestore();
    } catch (e) {
      // If online fetch fails, use locally saved lessons
    }

    final localLessonMaps = await _offlineLessonService.getLocalLessons();
    return localLessonMaps.map((map) => Lesson.fromMap(map)).toList();
  }

  List<Lesson> _filterLessons(List<Lesson> lessons) {
    if (searchQuery.trim().isEmpty) {
      return lessons;
    }

    final query = searchQuery.toLowerCase();

    return lessons.where((lesson) {
      return lesson.title.toLowerCase().contains(query) ||
          lesson.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                future: _loadLessons(),
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

                  final allLessons = snapshot.data ?? [];
                  final lessons = _filterLessons(allLessons);

                  if (lessons.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.text(lang, 'noLessonsFound'),
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: lessons.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LessonDetailScreen(lesson: lesson),
                            ),
                          );
                        },
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                lesson.isPublished
                                    ? Icons.arrow_forward_ios_rounded
                                    : Icons.visibility_off_rounded,
                                size: 18,
                                color: lesson.isPublished
                                    ? const Color(0xFF2D8CE0)
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
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
