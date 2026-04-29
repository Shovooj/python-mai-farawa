class PracticeModel {
  final String practiceId;
  final String lessonId;
  final String title;
  final String instruction;
  final String starterCode;
  final String expectedOutput;
  final int order;

  PracticeModel({
    required this.practiceId,
    required this.lessonId,
    required this.title,
    required this.instruction,
    required this.starterCode,
    required this.expectedOutput,
    required this.order,
  });

  factory PracticeModel.fromMap(Map<String, dynamic> map) {
    return PracticeModel(
      practiceId: map['practiceId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      title: map['title'] ?? '',
      instruction: map['instruction'] ?? '',
      starterCode: map['starterCode'] ?? '',
      expectedOutput: map['expectedOutput'] ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'practiceId': practiceId,
      'lessonId': lessonId,
      'title': title,
      'instruction': instruction,
      'starterCode': starterCode,
      'expectedOutput': expectedOutput,
      'order': order,
    };
  }
}
