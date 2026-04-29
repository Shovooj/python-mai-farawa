class QuizModel {
  final String quizId;
  final String lessonId;
  final String title;
  final int passingScore;
  final int totalQuestions;

  QuizModel({
    required this.quizId,
    required this.lessonId,
    required this.title,
    required this.passingScore,
    required this.totalQuestions,
  });

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      quizId: map['quizId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      title: map['title'] ?? '',
      passingScore: map['passingScore'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'lessonId': lessonId,
      'title': title,
      'passingScore': passingScore,
      'totalQuestions': totalQuestions,
    };
  }
}
