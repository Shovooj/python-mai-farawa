// ProgressModel: represents a learner's progress for a single lesson.
//
// Fields summary for beginners:
// - progressId: unique id (combination of user and lesson ids in this app)
// - lessonCompleted / practiceCompleted / quizCompleted / videoViewed: flags
// - score: best quiz score observed
// - videoPositionSeconds / videoDurationSeconds: last saved playback state
//
// This model includes helpers to convert loosely-typed database values
// (int/ String/ bool) into proper Dart types and toMap/fromMap helpers used
// when reading from or writing to the local DB / Firestore.
class ProgressModel {
  final String progressId;
  final String userId;
  final String lessonId;
  final bool lessonCompleted;
  final bool practiceCompleted;
  final bool quizCompleted;
  final bool videoViewed;
  final int score;
  final int videoPositionSeconds;
  final int videoDurationSeconds;

  ProgressModel({
    required this.progressId,
    required this.userId,
    required this.lessonId,
    required this.lessonCompleted,
    required this.practiceCompleted,
    required this.quizCompleted,
    required this.videoViewed,
    required this.score,
    required this.videoPositionSeconds,
    required this.videoDurationSeconds,
  });

  static bool toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static int toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ProgressModel(
      progressId: map['progressId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      lessonId: map['lessonId']?.toString() ?? '',
      lessonCompleted: toBool(map['lessonCompleted']),
      practiceCompleted: toBool(map['practiceCompleted']),
      quizCompleted: toBool(map['quizCompleted']),
      videoViewed: toBool(map['videoViewed']),
      score: toInt(map['score']),
      videoPositionSeconds: toInt(map['videoPositionSeconds']),
      videoDurationSeconds: toInt(map['videoDurationSeconds']),
    );
  }

  ProgressModel copyWith({
    String? progressId,
    String? userId,
    String? lessonId,
    bool? lessonCompleted,
    bool? practiceCompleted,
    bool? quizCompleted,
    bool? videoViewed,
    int? score,
    int? videoPositionSeconds,
    int? videoDurationSeconds,
  }) {
    return ProgressModel(
      progressId: progressId ?? this.progressId,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      lessonCompleted: lessonCompleted ?? this.lessonCompleted,
      practiceCompleted: practiceCompleted ?? this.practiceCompleted,
      quizCompleted: quizCompleted ?? this.quizCompleted,
      videoViewed: videoViewed ?? this.videoViewed,
      score: score ?? this.score,
      videoPositionSeconds: videoPositionSeconds ?? this.videoPositionSeconds,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'progressId': progressId,
      'userId': userId,
      'lessonId': lessonId,
      'lessonCompleted': lessonCompleted ? 1 : 0,
      'practiceCompleted': practiceCompleted ? 1 : 0,
      'quizCompleted': quizCompleted ? 1 : 0,
      'videoViewed': videoViewed ? 1 : 0,
      'score': score,
      'videoPositionSeconds': videoPositionSeconds,
      'videoDurationSeconds': videoDurationSeconds,
    };
  }
}
