// Lightweight model for a quiz associated with a lesson. Contains passing
// score and helper to fetch the localized title.
class QuizModel {
  final String quizId;
  final String lessonId;
  final String title;
  final String titleHa;
  final int passingScore;
  final int totalQuestions;

  QuizModel({
    required this.quizId,
    required this.lessonId,
    required this.title,
    required this.titleHa,
    required this.passingScore,
    required this.totalQuestions,
  });

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      quizId: map['quizId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      title: map['title'] ?? '',
      titleHa: map['titleHa'] ?? '',
      passingScore: map['passingScore'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
    );
  }

  String titleForLang(String lang) {
    if (lang == 'ha') {
      return (titleHa.trim().isNotEmpty) ? titleHa : title;
    }
    return title;
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'lessonId': lessonId,
      'title': title,
      'titleHa': titleHa,
      'passingScore': passingScore,
      'totalQuestions': totalQuestions,
    };
  }
}
