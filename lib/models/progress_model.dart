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

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      progressId: map['progressId'] ?? '',
      userId: map['userId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      lessonCompleted: map['lessonCompleted'] == true,
      practiceCompleted: map['practiceCompleted'] == true,
      quizCompleted: map['quizCompleted'] == true,
      videoViewed: map['videoViewed'] == true,
      score: (map['score'] ?? 0) as int,
      videoPositionSeconds: (map['videoPositionSeconds'] ?? 0) as int,
      videoDurationSeconds: (map['videoDurationSeconds'] ?? 0) as int,
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
      'lessonCompleted': lessonCompleted,
      'practiceCompleted': practiceCompleted,
      'quizCompleted': quizCompleted,
      'videoViewed': videoViewed,
      'score': score,
      'videoPositionSeconds': videoPositionSeconds,
      'videoDurationSeconds': videoDurationSeconds,
    };
  }
}
