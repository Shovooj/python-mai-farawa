import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sync_queue_service.dart';

class ProgressSyncService {
  final SyncQueueService _syncQueueService = SyncQueueService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No signed-in user found.');
    }
    return user.uid;
  }

  Future<void> syncPendingProgress() async {
    final pendingItems = await _syncQueueService.getPendingQueueItems();

    for (final item in pendingItems) {
      if (item['entityType'] != 'progress') continue;

      final int queueId = item['id'] as int;
      final Map<String, dynamic> payload = Map<String, dynamic>.from(
        jsonDecode(item['payload'] as String),
      );

      final String lessonId = payload['lessonId'] as String;
      final String docId = '${_uid}_$lessonId';

      await _firestore.collection('progress').doc(docId).set({
        'progressId': docId,
        'userId': _uid,
        'lessonId': lessonId,
        'lessonCompleted': payload['lessonCompleted'] == 1,
        'practiceCompleted': payload['practiceCompleted'] == 1,
        'quizCompleted': payload['quizCompleted'] == 1,
        'videoViewed': payload['videoViewed'] == 1,
        'score': payload['score'] ?? 0,
        'videoPositionSeconds': payload['videoPositionSeconds'] ?? 0,
        'videoDurationSeconds': payload['videoDurationSeconds'] ?? 0,
        'updatedAt': payload['updatedAt'],
      }, SetOptions(merge: true));

      await _syncQueueService.markQueueItemDone(queueId);
    }
  }
}
