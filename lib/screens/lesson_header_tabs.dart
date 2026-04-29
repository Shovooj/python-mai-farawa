import 'package:flutter/material.dart';

class LessonHeaderTabs extends StatelessWidget {
  final String activeTab;

  const LessonHeaderTabs({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 14, left: 22, right: 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderTab(title: 'Video', isActive: activeTab == 'video'),
              _HeaderTab(title: 'Quiz', isActive: activeTab == 'quiz'),
              _HeaderTab(title: 'Practice', isActive: activeTab == 'practice'),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _HeaderTab extends StatelessWidget {
  final String title;
  final bool isActive;

  const _HeaderTab({required this.title, required this.isActive});

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
          width: 40,
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
