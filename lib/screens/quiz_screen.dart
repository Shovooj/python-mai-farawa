import 'package:flutter/material.dart';
import '../models/lesson.dart';
import 'quiz_result_screen.dart';

// This screen displays the quiz for a selected lesson.
class QuizScreen extends StatefulWidget {
  final Lesson lesson;

  const QuizScreen({super.key, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Keeps track of the question currently being shown.
  int currentQuestionIndex = 0;

  // Stores the selected answer for each question.
  // Key = question index, Value = selected option index.
  final Map<int, int> selectedAnswers = {};

  // Holds the list of quiz questions for the current lesson.
  late final List<QuizQuestion> questions;

  @override
  void initState() {
    super.initState();

    // Load the correct quiz questions based on the lesson number.
    questions = _buildQuestionsForLesson(widget.lesson.number);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current question being displayed.
    final QuizQuestion question = questions[currentQuestionIndex];

    // Check whether the user has selected an option for this question.
    final int? selectedIndex = selectedAnswers[currentQuestionIndex];

    // Check whether this is the last question in the quiz.
    final bool isLastQuestion = currentQuestionIndex == questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          'Laccar ${widget.lesson.number}: ${widget.lesson.title}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 14, left: 22, right: 22),
            child: Column(
              children: const [
                // These tabs are only visual at the moment.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuizTab(title: 'Video', isActive: false),
                    _QuizTab(title: 'Jaraba', isActive: true),
                    _QuizTab(title: 'Aiki', isActive: false),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambaya ${currentQuestionIndex + 1} daga cikin ${questions.length}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Shows quiz progress from first to last question.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / questions.length,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2D8CE0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Displays the current quiz question text.
                  Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Builds all answer options for the current question.
                  ...List.generate(question.options.length, (index) {
                    final String option = question.options[index];
                    final bool isSelected = selectedIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          // Save the selected answer for this question.
                          setState(() {
                            selectedAnswers[currentQuestionIndex] = index;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2D8CE0)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? const Color(0xFF2D8CE0)
                                    : Colors.grey.shade400,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),

                  // Small indicators showing current and answered questions.
                  Row(
                    children: List.generate(questions.length, (index) {
                      final bool isActive = index == currentQuestionIndex;
                      final bool isAnswered = selectedAnswers[index] != null;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2D8CE0)
                              : isAnswered
                              ? Colors.green
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  const Spacer(),

                  // Navigation buttons for moving through the quiz.
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: currentQuestionIndex == 0
                                ? null
                                : () {
                                    setState(() {
                                      currentQuestionIndex--;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF2D8CE0),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              foregroundColor: const Color(0xFF2D8CE0),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Baya',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: selectedIndex == null
                                ? null
                                : () {
                                    if (isLastQuestion) {
                                      _finishQuiz();
                                    } else {
                                      setState(() {
                                        currentQuestionIndex++;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D8CE0),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isLastQuestion
                                  ? 'Gama Jaraba'
                                  : 'Tambaya Mai Gaba',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calculates the quiz score and opens the result screen.
  void _finishQuiz() {
    int score = 0;

    for (int i = 0; i < questions.length; i++) {
      final int? selected = selectedAnswers[i];
      if (selected != null && selected == questions[i].correctAnswerIndex) {
        score++;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          lesson: widget.lesson,
          score: score,
          totalQuestions: questions.length,
        ),
      ),
    );
  }

  // Returns quiz questions based on the current lesson number.
  List<QuizQuestion> _buildQuestionsForLesson(int lessonNumber) {
    switch (lessonNumber) {
      case 1:
        return [
          QuizQuestion(
            questionText:
                'Menene kalmar da ake amfani da ita wajen buga rubutu a kan allo a cikin Python?',
            options: ['A. input()', 'B. echo', 'C. print()', 'D. display()'],
            correctAnswerIndex: 2,
          ),
          QuizQuestion(
            questionText: 'Python wani irin yare ne?',
            options: [
              'A. Programming language',
              'B. Web browser',
              'C. Operating system',
              'D. Database',
            ],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            questionText: 'Wanne ne daidai wajen nuna rubutu a Python?',
            options: [
              'A. print("Sannu")',
              'B. echo("Sannu")',
              'C. show("Sannu")',
              'D. output("Sannu")',
            ],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            questionText: 'Ana amfani da Python domin?',
            options: [
              'A. Rubuta shirye-shirye',
              'B. Gyaran waya kawai',
              'C. Bugawa takarda kawai',
              'D. Kunna waka kawai',
            ],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            questionText: 'A cikin wannan lacca, ka fara koyon me?',
            options: [
              'A. Abin da Python yake nufi',
              'B. Zanen gini',
              'C. Chemistry',
              'D. Lissafin kudi',
            ],
            correctAnswerIndex: 0,
          ),
        ];

      default:
        return [
          QuizQuestion(
            questionText: 'Wannan tambaya ce ta gwaji domin wannan laccar.',
            options: ['A', 'B', 'C', 'D'],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            questionText: 'Wannan ita ce tambaya ta biyu.',
            options: ['A', 'B', 'C', 'D'],
            correctAnswerIndex: 1,
          ),
          QuizQuestion(
            questionText: 'Wannan ita ce tambaya ta uku.',
            options: ['A', 'B', 'C', 'D'],
            correctAnswerIndex: 2,
          ),
          QuizQuestion(
            questionText: 'Wannan ita ce tambaya ta hudu.',
            options: ['A', 'B', 'C', 'D'],
            correctAnswerIndex: 3,
          ),
          QuizQuestion(
            questionText: 'Wannan ita ce tambaya ta biyar.',
            options: ['A', 'B', 'C', 'D'],
            correctAnswerIndex: 0,
          ),
        ];
    }
  }
}

// Simple model class for one quiz question.
class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });
}

// Small reusable widget used for the top tab labels.
class _QuizTab extends StatelessWidget {
  final String title;
  final bool isActive;

  const _QuizTab({required this.title, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF2D8CE0) : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 52,
          height: 3,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2D8CE0) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
