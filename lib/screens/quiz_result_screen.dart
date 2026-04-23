import 'package:flutter/material.dart';
import '../models/lesson.dart';
import 'practice_screen.dart';
import 'quiz_screen.dart';

// This screen displays the user's quiz result.
class QuizResultScreen extends StatelessWidget {
  final Lesson lesson;
  final int score;
  final int totalQuestions;

  const QuizResultScreen({
    super.key,
    required this.lesson,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage score.
    final double percent = totalQuestions == 0 ? 0 : score / totalQuestions;

    // User passes only if score is 80% or above.
    final bool passed = percent >= 0.8;

    // Get feedback text based on result.
    final String feedback = _getFeedback(percent);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: const Text(
          'Sakamakon Jaraba',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Top result icon changes depending on pass/fail state.
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: passed
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.check_circle : Icons.info,
                  size: 70,
                  color: passed ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                passed ? 'Ka Ci Jaraba' : 'Ka Kammala Jaraba',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Shows the lesson the result belongs to.
              Text(
                'Laccar ${lesson.number}: ${lesson.title}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 28),

              // Result summary card.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sakamakonka',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$score / $totalQuestions',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D8CE0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Feedback message for the learner.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  feedback,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Spacer(),

              // Button to retake the quiz.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(lesson: lesson),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2D8CE0), width: 2),
                    foregroundColor: const Color(0xFF2D8CE0),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Sake Gwadawa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // Only show practice button if learner passed the quiz.
              if (passed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PracticeScreen(lesson: lesson),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Je zuwa Aiki',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Returns feedback message based on score percentage.
  String _getFeedback(double percent) {
    if (percent >= 0.8) {
      return 'Madalla sosai! Ka ci jaraba. Yanzu ka wuce zuwa bangaren aiki domin kammala wannan lacca.';
    } else if (percent >= 0.5) {
      return 'Ka yi kokari, amma dole ne ka samu akalla 80% kafin ka wuce zuwa aiki. Sake gwadawa.';
    } else {
      return 'Ka na bukatar karin fahimta. Sake duba darasin sannan ka sake gwadawa har sai ka kai akalla 80%.';
    }
  }
}
