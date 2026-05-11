// Small header tabs used on the lesson detail screen to switch between
// Video / Quiz / Practice labels. Purely presentational.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import '../localization/app_strings.dart';

/// Simple presentational widget that displays three header tabs: Video,
/// Quiz, and Practice. The currently active tab is highlighted.
class LessonHeaderTabs extends StatelessWidget {
  final String activeTab;

  const LessonHeaderTabs({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;

    final videoTab = AppStrings.text(lang, 'activeTabVideo');
    final quizTab = AppStrings.text(lang, 'activeTabQuiz');
    final practiceTab = AppStrings.text(lang, 'activeTabPractice');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 14, left: 22, right: 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderTab(title: videoTab, isActive: activeTab == videoTab),
              _HeaderTab(title: quizTab, isActive: activeTab == quizTab),
              _HeaderTab(
                title: practiceTab,
                isActive: activeTab == practiceTab,
              ),
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
    const activeGreen = Color(0xFF4CAF50);

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? activeGreen : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: isActive ? activeGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
