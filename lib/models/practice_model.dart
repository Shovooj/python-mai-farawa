class PracticeModel {
  final String practiceId;
  final String lessonId;
  final String title;
  final String titleHa;
  final String instruction;
  final String instructionHa;
  final String starterCode;
  final String expectedOutput;
  final String expectedOutputHa;
  final int order;

  PracticeModel({
    required this.practiceId,
    required this.lessonId,
    required this.title,
    required this.titleHa,
    required this.instruction,
    required this.instructionHa,
    required this.starterCode,
    required this.expectedOutput,
    required this.expectedOutputHa,
    required this.order,
  });

  factory PracticeModel.fromMap(Map<String, dynamic> map) {
    return PracticeModel(
      practiceId: map['practiceId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      title: map['title'] ?? '',
      titleHa: map['titleHa'] ?? '',
      instruction: map['instruction'] ?? '',
      instructionHa: map['instructionHa'] ?? '',
      starterCode: map['starterCode'] ?? '',
      expectedOutput: map['expectedOutput'] ?? '',
      expectedOutputHa: map['expectedOutputHa'] ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  String titleForLang(String lang) {
    if (lang == 'ha' || lang == 'hausa') {
      return (titleHa.trim().isNotEmpty) ? titleHa : title;
    }
    return title;
  }

  String instructionForLang(String lang) {
    if (lang == 'ha' || lang == 'hausa') {
      return (instructionHa.trim().isNotEmpty) ? instructionHa : instruction;
    }
    return instruction;
  }

  String expectedOutputForLang(String lang) {
    if (lang == 'ha' || lang == 'hausa') {
      return (expectedOutputHa.trim().isNotEmpty)
          ? expectedOutputHa
          : expectedOutput;
    }
    return expectedOutput;
  }

  Map<String, dynamic> toMap() {
    return {
      'practiceId': practiceId,
      'lessonId': lessonId,
      'title': title,
      'titleHa': titleHa,
      'instruction': instruction,
      'instructionHa': instructionHa,
      'starterCode': starterCode,
      'expectedOutput': expectedOutput,
      'expectedOutputHa': expectedOutputHa,
      'order': order,
    };
  }
}
