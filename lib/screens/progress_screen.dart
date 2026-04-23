import 'package:flutter/material.dart';
import '../data/lesson_data.dart';
import '../models/lesson.dart';

/// ProgressScreen shows overall learning statistics and
/// per‑lesson completion/lock status based on LessonData.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read all progress values once at build time.
    // If progress changes on another screen, calling setState()
    // when returning to this screen's parent will rebuild and
    // update these values.
    final int completedLessons = LessonData.completedCount;
    final int totalLessons = LessonData.lessons.length;
    final int progressPercent = (LessonData.progressPercent * 100).toInt();
    final int completedMinutes = LessonData.completedDurationMinutes;
    final int totalMinutes = LessonData.totalDurationMinutes;

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
          'Ci Gaba Na',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: completed lessons vs total lessons.
              Row(
                children: [
                  Expanded(
                    child: ProgressCard(
                      value: '$completedLessons',
                      label: 'Laccoci Cikakke',
                      valueColor: const Color(0xFF2D8CE0),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ProgressCard(
                      value: '$totalLessons',
                      label: 'Jimlar Laccoci',
                      valueColor: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Second row: overall percentage progress and time spent.
              Row(
                children: [
                  Expanded(
                    child: ProgressCard(
                      value: '$progressPercent%',
                      label: 'Jimlar Ci Gaba',
                      valueColor: const Color(0xFFFFC107),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ProgressCard(
                      value: '$completedMinutes / $totalMinutes min',
                      label: 'Lokacin Koyo',
                      valueColor: const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visual progress bar for total course completion.
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: LessonData.progressPercent,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2D8CE0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$progressPercent% an kammala',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              const Text(
                'Matsayin Laccoci',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable list of all lessons with status (completed/locked/open).
              Expanded(
                child: ListView.separated(
                  itemCount: LessonData.lessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final Lesson lesson = LessonData.lessons[index];
                    return _LessonStatusTile(lesson: lesson);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small card widget used to display a single numeric
/// progress stat and its label (e.g., "8" + "Laccoci Cikakke").
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
        // Optional: add shadow here later to match the visual
        // style of cards used in the home screen.
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main numeric value (e.g., "8" or "75%").
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const Spacer(),
          // Description of what the value represents.
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

/// List tile that shows the status of an individual lesson:
/// completed, locked or open.
class _LessonStatusTile extends StatelessWidget {
  final Lesson lesson;

  const _LessonStatusTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final bool completed = lesson.isCompleted;
    final bool locked = lesson.isLocked;

    // Derive icon, color and status text from the lesson state.
    IconData icon;
    Color color;
    String status;

    if (completed) {
      icon = Icons.check_circle;
      color = Colors.green;
      status = 'An kammala';
    } else if (locked) {
      icon = Icons.lock;
      color = Colors.black45;
      status = 'A kulle';
    } else {
      icon = Icons.play_circle_fill;
      color = const Color(0xFF2D8CE0);
      status = 'A bude';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson number + title.
                Text(
                  'Laccar ${lesson.number}: ${lesson.title}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // Status text (completed / locked / open).
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
