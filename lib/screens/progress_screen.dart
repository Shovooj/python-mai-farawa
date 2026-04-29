import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProgressService progressService = ProgressService();
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Progress',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: progressService.getUserProgressStream(),
        builder: (context, progressSnapshot) {
          if (progressSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (progressSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading progress: ${progressSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final progressList = progressSnapshot.data ?? [];

          return FutureBuilder(
            future: firestoreService.getPublishedLessons(),
            builder: (context, lessonSnapshot) {
              if (lessonSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (lessonSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading lessons: ${lessonSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final lessons =
                  (lessonSnapshot.data ?? [])
                      .where((lesson) => lesson.lessonNumber > 0)
                      .toList()
                    ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

              final lessonMap = {
                for (final lesson in lessons) lesson.lessonId: lesson,
              };

              final int totalLessons = lessons.length;
              final int completedLessons = progressList
                  .where((item) => item.lessonCompleted == true)
                  .length;

              final double progressFraction = totalLessons == 0
                  ? 0
                  : completedLessons / totalLessons;

              final int progressPercent = (progressFraction * 100).round();

              final int completedMinutes = progressList.fold(
                0,
                (sum, item) => sum + (item.videoPositionSeconds ~/ 60),
              );

              final int totalMinutes = lessons.fold(
                0,
                (sum, lesson) => sum + lesson.durationMinutes,
              );

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ProgressCard(
                              value: '$completedLessons',
                              label: 'Completed Lessons',
                              valueColor: const Color(0xFF2D8CE0),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ProgressCard(
                              value: '$totalLessons',
                              label: 'Total Lessons',
                              valueColor: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ProgressCard(
                              value: '$progressPercent%',
                              label: 'Total Progress',
                              valueColor: const Color(0xFFFFC107),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ProgressCard(
                              value: '$completedMinutes / $totalMinutes min',
                              label: 'Time Spent',
                              valueColor: const Color(0xFFFF6B6B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF2D8CE0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$progressPercent% of the courses completed',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: progressList.isEmpty
                            ? const Center(
                                child: Text(
                                  'No progress yet. Start a lesson to see your progress.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: progressList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = progressList[index];
                                  final lesson = lessonMap[item.lessonId];
                                  final lessonTitle =
                                      lesson?.title ?? 'Unknown Lesson';
                                  final lessonNumber = lesson?.lessonNumber;

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item.lessonCompleted
                                              ? Icons.check_circle
                                              : Icons.timelapse_rounded,
                                          color: item.lessonCompleted
                                              ? Colors.green
                                              : const Color(0xFF2D8CE0),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lessonNumber != null
                                                    ? 'Lesson $lessonNumber: $lessonTitle'
                                                    : lessonTitle,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Quiz: ${item.quizCompleted ? "Done" : "Not done"} | '
                                                'Practice: ${item.practiceCompleted ? "Done" : "Not done"} | '
                                                'Video: ${item.videoViewed ? "Done" : "Not done"}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const ProgressCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
