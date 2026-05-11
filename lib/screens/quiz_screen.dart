// Quiz screen: present quiz questions for a lesson and collect answers.
//
// Notes:
// - Tries to use locally cached quiz and questions first (offline-first).
// - Submitting the quiz navigates to `QuizResultScreen` where progress is
//   recorded locally and queued for remote sync.
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../services/firestore_service.dart';
import '../services/local_lesson_content_service.dart';
import 'lesson_header_tabs.dart';
import 'quiz_result_screen.dart';
import '../localization/app_strings.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/progress_model.dart';
import '../services/local_progress_service.dart';

class QuizScreen extends StatefulWidget {
  final Lesson lesson;

  const QuizScreen({super.key, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final LocalProgressService _localProgressService = LocalProgressService();

  Future<QuizModel?>? _quizFuture;
  Future<List<QuestionModel>>? _questionsFuture;
  String? _loadedQuizId;

  @override
  void initState() {
    super.initState();
    _quizFuture = loadQuiz();
  }

  final FirestoreService firestoreService = FirestoreService();
  final LocalLessonContentService localLessonContentService =
      LocalLessonContentService();

  int currentQuestionIndex = 0;
  final Map<int, int> selectedAnswers = {};

  Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<QuizModel?> loadQuiz() async {
    final lang = context.read<LanguageProvider>().languageCode;
    if (await hasInternet()) {
      try {
        final onlineQuiz = await firestoreService.getQuizByLessonId(
          widget.lesson.lessonId,
        );

        debugPrint(
          'QUIZ FOR LESSON ${widget.lesson.lessonId} -> '
          '${onlineQuiz == null ? "null" : onlineQuiz.quizId}',
        );

        if (onlineQuiz != null) {
          await localLessonContentService.cacheQuiz(
            quizId: onlineQuiz.quizId,
            lessonId: onlineQuiz.lessonId,
            title: onlineQuiz.titleForLang(lang),
            passingScore: onlineQuiz.passingScore,
            totalQuestions: onlineQuiz.totalQuestions,
          );

          return onlineQuiz;
        }
      } catch (e) {
        debugPrint('Online quiz fetch failed: $e');
      }
    }

    final localQuiz = await localLessonContentService.getQuizByLessonId(
      widget.lesson.lessonId,
    );

    if (localQuiz == null) return null;

    return QuizModel(
      quizId: localQuiz['quizId'] as String? ?? '',
      lessonId: localQuiz['lessonId'] as String? ?? '',
      title: localQuiz['title'] as String? ?? '',
      passingScore: (localQuiz['passingScore'] as int?) ?? 0,
      totalQuestions: (localQuiz['totalQuestions'] as int?) ?? 0,
      titleHa: localQuiz['titleHa'] as String? ?? '',
    );
  }

  Future<List<QuestionModel>> loadQuestions(String quizId) async {
    if (await hasInternet()) {
      try {
        debugPrint('ONLINE QUESTION FETCH START -> quizId=$quizId');

        final questionStream = await firestoreService.getQuestionsByQuizId(
          quizId,
        );
        final onlineQuestions = await questionStream.first;

        debugPrint(
          'ONLINE QUESTIONS COUNT FOR $quizId -> ${onlineQuestions.length}',
        );

        await localLessonContentService.cacheQuestions(
          quizId,
          onlineQuestions
              .map(
                (q) => {
                  'questionId': q.questionId,
                  'quizId': q.quizId,
                  'lessonId': q.lessonId,
                  'questionText': q.questionText,
                  'optionA': q.optionA,
                  'optionB': q.optionB,
                  'optionC': q.optionC,
                  'optionD': q.optionD,
                  'questionTextHa': q.questionTextHa,
                  'optionAHa': q.optionAHa,
                  'optionBHa': q.optionBHa,
                  'optionCHa': q.optionCHa,
                  'optionDHa': q.optionDHa,
                  'correctAnswer': q.correctAnswer,
                  'order': q.order,
                },
              )
              .toList(),
        );

        return onlineQuestions;
      } catch (e, st) {
        debugPrint('ONLINE QUESTION FETCH FAILED FOR $quizId -> $e');
        debugPrint('$st');
      }
    }

    final localRows = await localLessonContentService.getQuestionsByQuizId(
      quizId,
    );

    debugPrint('LOCAL QUESTIONS COUNT FOR $quizId -> ${localRows.length}');
    for (final row in localRows) {
      debugPrint(
        'LOCAL QUESTION -> id=${row['questionId']}, quizId=${row['quizId']}, lessonId=${row['lessonId']}, order=${row['order']}',
      );
    }

    return localRows
        .map(
          (row) => QuestionModel(
            questionId: row['questionId'] as String? ?? '',
            quizId: row['quizId'] as String? ?? '',
            lessonId: row['lessonId'] as String? ?? widget.lesson.lessonId,
            questionText: row['questionText'] as String? ?? '',
            optionA: row['optionA'] as String? ?? '',
            optionB: row['optionB'] as String? ?? '',
            optionC: row['optionC'] as String? ?? '',
            optionD: row['optionD'] as String? ?? '',
            correctAnswer: row['correctAnswer'] as String? ?? '',
            order: (row['order'] as int?) ?? 0,
            questionTextHa: row['questionTextHa'] as String? ?? '',
            optionAHa: row['optionAHa'] as String? ?? '',
            optionBHa: row['optionBHa'] as String? ?? '',
            optionCHa: row['optionCHa'] as String? ?? '',
            optionDHa: row['optionDHa'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<String> getUid() async {
    final lang = context.read<LanguageProvider>().languageCode;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(AppStrings.text(lang, 'noSignedInUserFound'));
    }

    return user.uid;
  }

  Future<ProgressModel?> getExistingLocalProgress(String uid) async {
    return _localProgressService.getLocalProgressForLesson(
      userId: uid,
      lessonId: widget.lesson.lessonId,
    );
  }

  Future<void> finishQuiz({
    required QuizModel quiz,
    required List<QuestionModel> questions,
  }) async {
    int score = 0;

    for (int i = 0; i < questions.length; i++) {
      final selected = selectedAnswers[i];
      final question = questions[i];
      final correctIndex = correctAnswerIndex(question);

      if (selected != null && selected == correctIndex) {
        score++;
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          lesson: widget.lesson,
          quiz: quiz,
          score: score,
          totalQuestions: questions.length,
        ),
      ),
    );
  }

  int correctAnswerIndex(QuestionModel question) {
    final lang = context.read<LanguageProvider>().languageCode;
    final correct = question.correctAnswer.trim();

    if (correct == 'A' || correct == 'a') return 0;
    if (correct == 'B' || correct == 'b') return 1;
    if (correct == 'C' || correct == 'c') return 2;
    if (correct == 'D' || correct == 'd') return 3;

    if (correct == question.optionAForLang(lang)) return 0;
    if (correct == question.optionBForLang(lang)) return 1;
    if (correct == question.optionCForLang(lang)) return 2;
    if (correct == question.optionDForLang(lang)) return 3;

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Text(
          '${AppStrings.text(lang, 'lesson')} ${widget.lesson.lessonNumber}: ${widget.lesson.titleForLang(lang)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          LessonHeaderTabs(activeTab: AppStrings.text(lang, 'activeTabQuiz')),
          Expanded(
            child: FutureBuilder<QuizModel?>(
              future: _quizFuture,
              builder: (context, quizSnapshot) {
                if (quizSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (quizSnapshot.hasError) {
                  return Center(
                    child: Text(
                      '${AppStrings.text(lang, 'errorLoadingQuiz')}: ${quizSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final quiz = quizSnapshot.data;
                if (quiz == null) {
                  return Center(
                    child: Text(
                      AppStrings.text(lang, 'noQuizFoundForLesson'),
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  );
                }

                if (_loadedQuizId != quiz.quizId) {
                  _loadedQuizId = quiz.quizId;
                  _questionsFuture = loadQuestions(quiz.quizId);
                }

                return FutureBuilder<List<QuestionModel>>(
                  future: _questionsFuture,
                  builder: (context, questionSnapshot) {
                    if (questionSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (questionSnapshot.hasError) {
                      return Center(
                        child: Text(
                          '${AppStrings.text(lang, 'errorLoadingQuestions')}: ${questionSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final questions = questionSnapshot.data ?? [];

                    if (questions.isEmpty) {
                      return Center(
                        child: Text(
                          AppStrings.text(lang, 'noQuestionsFoundForQuiz'),
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                      );
                    }

                    if (currentQuestionIndex >= questions.length) {
                      currentQuestionIndex = 0;
                    }

                    final question = questions[currentQuestionIndex];

                    final selectedIndex = selectedAnswers[currentQuestionIndex];
                    final isLastQuestion =
                        currentQuestionIndex == questions.length - 1;

                    final options = [
                      question.optionAForLang(lang),
                      question.optionBForLang(lang),
                      question.optionCForLang(lang),
                      question.optionDForLang(lang),
                    ];

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppStrings.text(lang, 'question')} ${currentQuestionIndex + 1} ${AppStrings.text(lang, 'of')} ${questions.length}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value:
                                  (currentQuestionIndex + 1) / questions.length,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2D8CE0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            question.questionTextForLang(lang),
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.4,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...List.generate(options.length, (index) {
                            final option = options[index];
                            final isSelected = selectedIndex == index;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedAnswers[currentQuestionIndex] =
                                        index;
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
                          Row(
                            children: List.generate(questions.length, (index) {
                              final isActive = index == currentQuestionIndex;
                              final isAnswered = selectedAnswers[index] != null;

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
                                    child: Text(
                                      AppStrings.text(lang, 'previousQuestion'),
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
                                        : () async {
                                            if (isLastQuestion) {
                                              await finishQuiz(
                                                quiz: quiz,
                                                questions: questions,
                                              );
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
                                          ? AppStrings.text(lang, 'submit')
                                          : AppStrings.text(
                                              lang,
                                              'nextQuestion',
                                            ),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
