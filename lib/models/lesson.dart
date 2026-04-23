// This model represents one lesson in the app.
class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final int number;
  final String durationText;
  final int durationMinutes;
  final String summary;
  final String? videoUrl;
  final bool isCompleted;
  final bool isLocked;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.number,
    required this.durationText,
    required this.durationMinutes,
    required this.summary,
    this.videoUrl,
    this.isCompleted = false,
    this.isLocked = false,
  });

  // This method creates a new lesson object by copying the current one
  // and only changing the values that are passed in.
  // It is useful when updating completion state or lock state.
  Lesson copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? number,
    String? durationText,
    int? durationMinutes,
    String? summary,
    String? videoUrl,
    bool? isCompleted,
    bool? isLocked,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      number: number ?? this.number,
      durationText: durationText ?? this.durationText,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      summary: summary ?? this.summary,
      videoUrl: videoUrl ?? this.videoUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
