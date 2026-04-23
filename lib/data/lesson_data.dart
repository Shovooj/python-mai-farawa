import '../models/lesson.dart';
import 'lesson_storage.dart';

// This class manages all the lesson data used across the app.
// It also handles lesson progress, locking, unlocking, and saving progress.
class LessonData {
  // This creates the default lesson list used when the app starts for the first time
  // or when progress is reset.
  static List<Lesson> _initialLessons() => [
    const Lesson(
      id: 'lesson1',
      number: 1,
      title: 'Introduction to Python',
      subtitle: 'Lesson 1',
      durationText: '5 minutes',
      durationMinutes: 5,
      summary:
          'In this lesson, we will learn what Python is, how to write the first program, and how to display output on the screen.',
      videoUrl: null,
      isCompleted: false,
      isLocked: false,
    ),
    const Lesson(
      id: 'lesson2',
      number: 2,
      title: 'Variables',
      subtitle: 'Lesson 2',
      durationText: '5 minutes',
      durationMinutes: 5,
      summary:
          'In this lesson, we will learn about variables and how to store data such as numbers, text, and true or false values.',
      videoUrl: null,
      isCompleted: false,
      isLocked: true,
    ),
    const Lesson(
      id: 'lesson3',
      number: 3,
      title: 'Data Types',
      subtitle: 'Lesson 3',
      durationText: '5 minutes',
      durationMinutes: 5,
      summary:
          'In this lesson, we will learn how Python handles different types of data such as integers, strings, and booleans.',
      videoUrl: null,
      isCompleted: false,
      isLocked: true,
    ),
    const Lesson(
      id: 'lesson4',
      number: 4,
      title: 'Input and Output',
      subtitle: 'Lesson 4',
      durationText: '5 minutes',
      durationMinutes: 5,
      summary:
          'In this lesson, we will learn how Python receives input from the user and how it displays output.',
      videoUrl: null,
      isCompleted: false,
      isLocked: true,
    ),
    const Lesson(
      id: 'lesson5',
      number: 5,
      title: 'Loops',
      subtitle: 'Lesson 5',
      durationText: '5 minutes',
      durationMinutes: 5,
      summary:
          'In this lesson, we will learn how to repeat actions using for and while loops in Python.',
      videoUrl: null,
      isCompleted: false,
      isLocked: true,
    ),
    const Lesson(
      id: 'lesson6',
      number: 6,
      title: 'Conditions',
      subtitle: 'Lesson 6',
      durationText: '5 minutes',
      durationMinutes: 5,
      summary:
          'In this lesson, we will learn how to use conditions to make decisions in a Python program.',
      videoUrl: null,
      isCompleted: false,
      isLocked: true,
    ),
  ];

  // This holds the current lesson list the app is using.
  static List<Lesson> lessons = _initialLessons();

  // This returns how many lessons have been completed.
  static int get completedCount {
    return lessons.where((lesson) => lesson.isCompleted).length;
  }

  // This returns the overall progress as a decimal value.
  // Example: 0.5 means 50% completed.
  static double get progressPercent {
    if (lessons.isEmpty) return 0;
    return completedCount / lessons.length;
  }

  // This calculates the total lesson time for all lessons.
  static int get totalDurationMinutes {
    return lessons.fold(0, (sum, lesson) => sum + lesson.durationMinutes);
  }

  // This calculates only the duration of completed lessons.
  static int get completedDurationMinutes {
    return lessons
        .where((lesson) => lesson.isCompleted)
        .fold(0, (sum, lesson) => sum + lesson.durationMinutes);
  }

  // This prepares the lessons when the app starts.
  // It loads saved completed lessons from storage and updates the lesson list.
  static Future<void> initializeLessons() async {
    lessons = _initialLessons();

    final completedIds = await LessonStorage.getCompletedLessonIds();

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final isCompleted = completedIds.contains(lesson.id);

      lessons[i] = lesson.copyWith(isCompleted: isCompleted);
    }

    // After loading completion data, refresh the lock state of each lesson.
    _refreshLessonLocks();
  }

  // This marks one lesson as completed, refreshes lesson locks,
  // and saves the new progress to local storage.
  static Future<void> completeLesson(String lessonId) async {
    final int lessonIndex = lessons.indexWhere(
      (lesson) => lesson.id == lessonId,
    );

    // If the lesson is not found, stop here.
    if (lessonIndex == -1) return;

    final Lesson currentLesson = lessons[lessonIndex];

    lessons[lessonIndex] = currentLesson.copyWith(
      isCompleted: true,
      isLocked: false,
    );

    // Update which lessons should be locked or unlocked.
    _refreshLessonLocks();

    // Save all completed lesson IDs so the progress remains after restart.
    await LessonStorage.saveCompletedLessonIds(
      lessons
          .where((lesson) => lesson.isCompleted)
          .map((lesson) => lesson.id)
          .toList(),
    );
  }

  // This controls the lock logic of the lessons.
  // Lesson 1 is always open.
  // Every other lesson stays locked until the previous one is completed.
  static void _refreshLessonLocks() {
    for (int i = 0; i < lessons.length; i++) {
      if (i == 0) {
        lessons[i] = lessons[i].copyWith(isLocked: false);
      } else {
        final bool shouldLock = !lessons[i - 1].isCompleted;
        lessons[i] = lessons[i].copyWith(isLocked: shouldLock);
      }
    }
  }

  // This clears all saved progress and returns the lesson list to the default state.
  static Future<void> resetProgress() async {
    await LessonStorage.clearCompletedLessons();
    lessons = _initialLessons();
    _refreshLessonLocks();
  }
}
