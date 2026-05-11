// Model for practice tasks/exercises tied to lessons. Includes both
// English and Hausa fields and helper methods to pick the correct text.
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
      practiceId: map['practiceId']?.toString() ?? '',
      lessonId: map['lessonId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      instruction: map['instruction']?.toString() ?? '',
      starterCode: map['starterCode']?.toString() ?? '',
      expectedOutput: map['expectedOutput']?.toString() ?? '',
      order: map['order'] is int
          ? map['order'] as int
          : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      titleHa: map['titleHa']?.toString() ?? '',
      instructionHa: map['instructionHa']?.toString() ?? '',
      expectedOutputHa: map['expectedOutputHa']?.toString() ?? '',
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
