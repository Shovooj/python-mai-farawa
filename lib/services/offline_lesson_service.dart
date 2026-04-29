import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class OfflineLessonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> cacheLessonsFromFirestore() async {
    final snapshot = await _firestore.collection('lessons').get();
    final db = await DatabaseHelper.instance.database;

    final batch = db.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      batch.insert('lessons', {
        'lessonId': doc.id,
        'lessonNumber': data['lessonNumber'] ?? 0,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'contentBody': data['contentBody'] ?? '',
        'durationMinutes': data['durationMinutes'] ?? 0,
        'videoUrl': data['videoUrl'] ?? '',
        'isPublished': (data['isPublished'] ?? true) ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getLocalLessons() async {
    final db = await DatabaseHelper.instance.database;

    return await db.query(
      'lessons',
      where: 'isPublished = ?',
      whereArgs: [1],
      orderBy: 'lessonNumber ASC',
    );
  }
}
