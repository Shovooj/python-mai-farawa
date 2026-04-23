import 'package:flutter/material.dart';
import '../data/lesson_data.dart';

// Settings screen for app preferences and account-related actions.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Stores the currently selected language.
  String _currentLanguage = 'Hausa';

  // Stores whether notifications are enabled or disabled.
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    // Display text based on notification state.
    final String notificationText = _notificationsEnabled ? 'Kunnawa' : 'Kashe';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D8CE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        titleSpacing: 0,
        title: const Text(
          'Saituna',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),

          // Main column for the whole page.
          child: Column(
            children: [
              // Top section takes remaining space.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile card section.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            // Circle avatar.
                            Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE7EEF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'JD',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D8CE0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // User details.
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'John Doe',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'johndoe@gmail.com',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Language settings row.
                      SettingsRow(
                        title: 'Harshe',
                        trailingText: _currentLanguage,
                        onTap: _showLanguageDialog,
                      ),
                      const SizedBox(height: 10),

                      // Notification settings row.
                      SettingsRow(
                        title: 'Sanarwa',
                        trailingText: notificationText,
                        onTap: _toggleNotifications,
                      ),
                      const SizedBox(height: 10),

                      // About app row.
                      const SettingsRow(title: 'Game da Wannan Aikace-aikace'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom action buttons stay fixed near the bottom.
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showLogoutDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF453A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Fita',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _confirmResetProgress,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF453A),
                    side: const BorderSide(
                      color: Color(0xFFFF453A),
                      width: 1.4,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Share hana lissafina',
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
        ),
      ),
    );
  }

  // Toggles notification state between ON and OFF.
  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
  }

  // Shows confirmation dialog before resetting progress.
  Future<void> _confirmResetProgress() async {
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Share bayanai?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Wannan zai goge duk ci gaban da ka yi a laccoci. Kana son ka ci gaba?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('A’a'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Eh'),
            ),
          ],
        );
      },
    );

    // Stop here if user cancels reset.
    if (shouldReset != true) return;

    // Reset lesson progress from shared data source.
    await LessonData.resetProgress();

    if (!mounted) return;

    // Return to previous screen and trigger refresh there.
    Navigator.pop(context, true);
  }

  // Shows confirmation dialog before leaving the settings screen.
  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Fita daga manhaja?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('Kana son fita daga wannan shafin saituna?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('A’a'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Fita'),
            ),
          ],
        );
      },
    );
  }

  // Opens a dialog for selecting app language.
  void _showLanguageDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Zaɓi harshe',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOptionTile(
                label: 'Hausa',
                selected: _currentLanguage == 'Hausa',
                onTap: () {
                  setState(() {
                    _currentLanguage = 'Hausa';
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _LanguageOptionTile(
                label: 'English',
                selected: _currentLanguage == 'English',
                onTap: () {
                  setState(() {
                    _currentLanguage = 'English';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Reusable tile widget for language selection dialog.
class _LanguageOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: Color(0xFF2D8CE0))
          : null,
      onTap: onTap,
    );
  }
}

// Reusable settings row widget.
class SettingsRow extends StatelessWidget {
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.title,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          if (trailingText != null) ...[
            Text(
              trailingText!,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded, color: Colors.black45),
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: row,
    );
  }
}
