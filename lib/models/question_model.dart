class QuestionModel {
  final String questionId;
  final String quizId;
  final String lessonId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final int order;

  QuestionModel({
    required this.questionId,
    required this.quizId,
    required this.lessonId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.order,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionId: map['questionId'] ?? '',
      quizId: map['quizId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      questionText: map['questionText'] ?? '',
      optionA: map['optionA'] ?? '',
      optionB: map['optionB'] ?? '',
      optionC: map['optionC'] ?? '',
      optionD: map['optionD'] ?? '',
      correctAnswer: map['correctAnswer'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'quizId': quizId,
      'lessonId': lessonId,
      'questionText': questionText,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
      'correctAnswer': correctAnswer,
      'order': order,
    };
  }
}
