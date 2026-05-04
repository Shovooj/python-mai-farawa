class Lesson {
  final String lessonId;
  final int lessonNumber;
  final String title;
  final String titleHa;
  final String description;
  final String descriptionHa;
  final String contentBody;
  final int durationMinutes;
  final String language;
  final String videoUrl;
  final bool isPublished;

  Lesson({
    required this.lessonId,
    required this.lessonNumber,
    required this.title,
    required this.titleHa,
    required this.description,
    required this.descriptionHa,
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
      titleHa: map['titleHa'] ?? '',
      description: map['description'] ?? '',
      descriptionHa: map['descriptionHa'] ?? '',
      contentBody: map['contentBody'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      language: map['language'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      isPublished: map['isPublished'] == true || map['isPublished'] == 1,
    );
  }
  String titleForLang(String lang) {
    if (lang == 'ha' || lang == 'hausa') {
      // fallback to English if Hausa empty
      return (titleHa.trim().isNotEmpty) ? titleHa : title;
    }
    // default English
    return title;
  }

  String descriptionForLang(String lang) {
    if (lang == 'ha' || lang == 'hausa') {
      return (descriptionHa.trim().isNotEmpty) ? descriptionHa : description;
    }
    return description;
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'lessonNumber': lessonNumber,
      'title': title,
      'titleHa': titleHa,
      'description': description,
      'descriptionHa': descriptionHa,
      'contentBody': contentBody,
      'durationMinutes': durationMinutes,
      'language': language,
      'videoUrl': videoUrl,
      'isPublished': isPublished,
    };
  }
}
