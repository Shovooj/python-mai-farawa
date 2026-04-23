import 'package:shared_preferences/shared_preferences.dart';

// This class is responsible for saving and retrieving
// completed lesson information from local device storage.
class LessonStorage {
  // Key used to store the list of completed lesson IDs
  // inside SharedPreferences.
  static const String completedLessonsKey = 'completed_lessons';

  // Gets the list of completed lesson IDs from local storage.
  // If nothing has been saved yet, it returns an empty list.
  static Future<List<String>> getCompletedLessonIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(completedLessonsKey) ?? [];
  }

  // Saves the full list of completed lesson IDs to local storage.
  // This is useful when the app needs to update the stored progress.
  static Future<void> saveCompletedLessonIds(List<String> lessonIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(completedLessonsKey, lessonIds);
  }

  // Marks one lesson as completed.
  // It first loads the existing completed lessons,
  // checks whether the lesson ID already exists,
  // and if not, adds it and saves the updated list.
  static Future<void> markLessonCompleted(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(completedLessonsKey) ?? [];

    if (!completed.contains(lessonId)) {
      completed.add(lessonId);
      await prefs.setStringList(completedLessonsKey, completed);
    }
  }

  // Clears all saved lesson progress from local storage.
  // This can be used for reset progress functionality.
  static Future<void> clearCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(completedLessonsKey);
  }
}
