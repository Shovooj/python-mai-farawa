import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../data/lesson_data.dart';
import 'home_screen.dart';
import 'lesson_detail_screen.dart';

// This screen gives the learner a simple practice area after passing the quiz.
class PracticeScreen extends StatefulWidget {
  final Lesson lesson;

  const PracticeScreen({super.key, required this.lesson});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  // Controller used to read and edit code typed by the learner.
  final TextEditingController codeController = TextEditingController();

  // Text shown in the output area.
  String output = 'Sakamakon code zai bayyana a nan.';

  // Used to show loading while "running" code.
  bool isRunning = false;

  // Used to prevent multiple taps when completing a lesson.
  bool isCompletingLesson = false;

  // Controls whether the lesson completion success UI should be shown.
  bool lessonCompleted = false;

  @override
  void initState() {
    super.initState();

    // Load starter code when the practice screen opens.
    codeController.text = starterCode;
  }

  // Starter Python code shown to the learner by default.
  String get starterCode {
    return '''print("Sannu Duniya")

name = "Ali"
print(name)''';
  }

  // Finds the next lesson so the learner can continue after completion.
  Lesson? get nextLesson {
    final lessons = LessonData.lessons;
    final currentIndex = lessons.indexWhere((l) => l.id == widget.lesson.id);

    if (currentIndex == -1 || currentIndex + 1 >= lessons.length) {
      return null;
    }

    return lessons[currentIndex + 1];
  }

  // Simulates running code in the current prototype version.
  Future<void> runCode() async {
    setState(() {
      isRunning = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final String code = codeController.text.trim();
    String result;

    if (code.isEmpty) {
      result = 'Da fatan za ka rubuta Python code kafin ka danna Run.';
    } else if (code.contains('print')) {
      result =
          'An karbi code dinka. Wannan shi ne gwajin farko na practice area. '
          'A gaba za a iya hada Skulpt ko backend domin gudanar da code na gaske.';
    } else {
      result =
          'An ajiye code dinka, amma ka tabbata kana amfani da print domin fitar da sakamako.';
    }

    setState(() {
      output = result;
      isRunning = false;
    });
  }

  // Clears the editor and resets the output message.
  void clearCode() {
    setState(() {
      codeController.clear();
      output = 'An goge code. Sakamakon code zai bayyana a nan.';
    });
  }

  // Marks the lesson as completed and updates shared lesson progress.
  Future<void> completeLesson() async {
    if (isCompletingLesson || lessonCompleted) return;

    setState(() {
      isCompletingLesson = true;
    });

    await LessonData.completeLesson(widget.lesson.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('An kammala wannan lacca cikin nasara!'),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {
      isCompletingLesson = false;
      lessonCompleted = true;
    });
  }

  // Takes the learner back to the home screen and clears old routes.
  void goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  // Opens the next lesson if available, otherwise returns home.
  void goToNextLesson() {
    final next = nextLesson;

    if (next == null) {
      goHome();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LessonDetailScreen(lesson: next)),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final Lesson? upcomingLesson = nextLesson;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        title: Text(
          'Aiki - Lacca ${lesson.number}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          // Show either the completion UI or the normal practice UI.
          child: lessonCompleted
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 72,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'An kammala Lacca ${lesson.number}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${lesson.title} ta kammala cikin nasara.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            upcomingLesson != null
                                ? 'Za ka iya komawa gida ko ka wuce zuwa lacca ta gaba.'
                                : 'Wannan ita ce lacca ta karshe. Za ka iya komawa gida.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Button to return to home screen.
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: goHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D8CE0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Koma Gida',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Button to continue to the next lesson if one exists.
                    if (upcomingLesson != null)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: goToNextLesson,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Je zuwa Lacca ${upcomingLesson.number}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  children: [
                    // Practice instruction card.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Rubuta karamin Python code a kasa sannan ka gwada shi.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Code editor area.
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: codeController,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Rubuta Python code a nan...',
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Buttons for clearing and running code.
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: clearCode,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2D8CE0),
                                side: const BorderSide(
                                  color: Color(0xFF2D8CE0),
                                  width: 2,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Goge',
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
                              onPressed: isRunning ? null : runCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isRunning
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Run Code',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Output area for simulated code result.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sakamako',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            output,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Button to complete this lesson.
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isCompletingLesson ? null : completeLesson,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D8CE0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isCompletingLesson
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Kammala Wannan Lacca',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
