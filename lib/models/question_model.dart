class QuestionModel {
  final String questionId;
  final String quizId;
  final String lessonId;
  final String questionTextHa;
  final String optionAHa;
  final String optionBHa;
  final String optionCHa;
  final String optionDHa;
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
    required this.questionTextHa,
    required this.optionA,
    required this.optionAHa,
    required this.optionB,
    required this.optionBHa,
    required this.optionC,
    required this.optionCHa,
    required this.optionD,
    required this.optionDHa,
    required this.correctAnswer,
    required this.order,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionId: map['questionId']?.toString() ?? '',
      quizId: map['quizId']?.toString() ?? '',
      lessonId: map['lessonId']?.toString() ?? '',
      questionText: map['questionText']?.toString() ?? '',
      optionA: map['optionA']?.toString() ?? '',
      optionB: map['optionB']?.toString() ?? '',
      optionC: map['optionC']?.toString() ?? '',
      optionD: map['optionD']?.toString() ?? '',
      correctAnswer: map['correctAnswer']?.toString() ?? '',
      order: map['order'] is int
          ? map['order'] as int
          : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      questionTextHa: map['questionTextHa']?.toString() ?? '',
      optionAHa: map['optionAHa']?.toString() ?? '',
      optionBHa: map['optionBHa']?.toString() ?? '',
      optionCHa: map['optionCHa']?.toString() ?? '',
      optionDHa: map['optionDHa']?.toString() ?? '',
    );
  }

  String questionTextForLang(String lang) {
    if (lang == 'ha') {
      return (questionTextHa.trim().isNotEmpty) ? questionTextHa : questionText;
    }
    return questionText;
  }

  String optionAForLang(String lang) {
    if (lang == 'ha') {
      return (optionAHa.trim().isNotEmpty) ? optionAHa : optionA;
    }
    return optionA;
  }

  String optionBForLang(String lang) {
    if (lang == 'ha') {
      return (optionBHa.trim().isNotEmpty) ? optionBHa : optionB;
    }
    return optionB;
  }

  String optionCForLang(String lang) {
    if (lang == 'ha') {
      return (optionCHa.trim().isNotEmpty) ? optionCHa : optionC;
    }
    return optionC;
  }

  String optionDForLang(String lang) {
    if (lang == 'ha') {
      return (optionDHa.trim().isNotEmpty) ? optionDHa : optionD;
    }
    return optionD;
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'quizId': quizId,
      'lessonId': lessonId,
      'questionText': questionText,
      'questionTextHa': questionTextHa,
      'optionA': optionA,
      'optionAHa': optionAHa,
      'optionB': optionB,
      'optionBHa': optionBHa,
      'optionC': optionC,
      'optionCHa': optionCHa,
      'optionD': optionD,
      'optionDHa': optionDHa,
      'correctAnswer': correctAnswer,
      'order': order,
    };
  }
}
