import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';
import '../localization/app_strings.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
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
        title: Text(
          AppStrings.text(lang, 'progress'),
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
                '${AppStrings.text(lang, 'errorLoadingProgress')} ${progressSnapshot.error}',
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
                    '${AppStrings.text(lang, 'errorLoadingLessons')} ${lessonSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final lessons =
                  (lessonSnapshot.data ?? [])
                      .where((lesson) => lesson.lessonNumber > 0)
                      .toList()
                    ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

              final int totalLessons = lessons.length;
              final int completedLessons = progressList
                  .where((item) => item.lessonCompleted == true)
                  .length;

              final double progressFraction = totalLessons == 0
                  ? 0
                  : completedLessons / totalLessons;

              final int progressPercent = (progressFraction * 100).round();

              final int completedSeconds = progressList.fold(
                0,
                (sum, item) => sum + item.videoPositionSeconds,
              );

              final int completedMinutes = completedSeconds ~/ 60;

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
                              label: AppStrings.text(lang, 'completedLessons'),
                              valueColor: const Color(0xFF2D8CE0),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ProgressCard(
                              value: '$totalLessons',
                              label: AppStrings.text(lang, 'totalLessons'),
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
                              label: AppStrings.text(lang, 'totalProgress'),
                              valueColor: const Color(0xFFFFC107),
                            ),
                          ),
                          Expanded(
                            child: ProgressCard(
                              value:
                                  '$completedMinutes / $totalMinutes ${AppStrings.text(lang, 'min')}',
                              label: AppStrings.text(lang, 'videoTime'),
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
                        '$progressPercent% ${AppStrings.text(lang, 'ofCoursesCompleted')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
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
