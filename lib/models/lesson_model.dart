class Lesson {
  final String lessonId;
  final int lessonNumber;
  final String title;
  final String description;
  final String contentBody;
  final int durationMinutes;
  final String language;
  final String videoUrl;
  final bool isPublished;

  Lesson({
    required this.lessonId,
    required this.lessonNumber,
    required this.title,
    required this.description,
    required this.contentBody,
    required this.durationMinutes,
    required this.language,
    required this.videoUrl,
    required this.isPublished,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      lessonId: map['lessonId'] ?? '',
      lessonNumber: map['lessonNumber'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      contentBody: map['contentBody'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      language: map['language'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      isPublished: map['isPublished'] == true || map['isPublished'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'lessonNumber': lessonNumber,
      'title': title,
      'description': description,
      'contentBody': contentBody,
      'durationMinutes': durationMinutes,
      'language': language,
      'videoUrl': videoUrl,
      'isPublished': isPublished,
    };
  }
}
