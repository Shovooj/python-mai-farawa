import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _languageKey = 'app_language';

  User? _currentUser;

  String _fullName = 'User';
  String _email = 'No email available';
  String _initials = 'U';
  String _currentLanguage = 'English';

  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadSavedLanguage(), _loadUserProfile()]);
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? 'English';

      if (!mounted) return;
      setState(() {
        _currentLanguage = savedLanguage;
      });
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }

  Future<void> _saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);

      if (!mounted) return;
      setState(() {
        _currentLanguage = language;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to $language'),
          backgroundColor: const Color(0xFF2D8CE0),
        ),
      );
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      final String? firestoreName = userDoc.data()?['fullName'] as String?;
      final String? firebaseEmail = _currentUser?.email;

      final resolvedName =
          (firestoreName != null && firestoreName.trim().isNotEmpty)
          ? firestoreName.trim()
          : 'User';

      final resolvedEmail =
          (firebaseEmail != null && firebaseEmail.trim().isNotEmpty)
          ? firebaseEmail.trim()
          : 'No email available';

      if (!mounted) return;

      setState(() {
        _fullName = resolvedName;
        _email = resolvedEmail;
        _initials = _generateInitials(resolvedName);
      });
    } catch (e) {
      debugPrint('Error loading Firestore profile: $e');
    }
  }

  String _generateInitials(String fullName) {
    if (fullName.trim().isEmpty) return 'U';

    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _showLanguageDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select language',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOptionTile(
                label: 'English',
                selected: _currentLanguage == 'English',
                onTap: () async {
                  Navigator.pop(context);
                  await _saveLanguage('English');
                },
              ),
              const SizedBox(height: 8),
              _LanguageOptionTile(
                label: 'Hausa',
                selected: _currentLanguage == 'Hausa',
                onTap: () async {
                  Navigator.pop(context);
                  await _saveLanguage('Hausa');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutAppDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'About App',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Python Mai Farawa is a beginner-friendly mobile learning application '
              'designed to help users learn Python programming step by step in a simple '
              'and accessible way.\n\n'
              'The app provides lessons, quizzes, practice exercises, learning progress '
              'tracking, and bilingual support to improve the learning experience.\n\n'
              'This application was developed as part of an academic software engineering '
              'project.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await FirebaseAuth.instance.signOut();

                if (!mounted) return;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete account?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'This will permanently delete your account and profile data. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Color(0xFF2D8CE0),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Failed to delete account. Please try again.';

      if (e.code == 'requires-recent-login') {
        message =
            'For security reasons, please log out, log in again, then try deleting your account.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An unexpected error occurred while deleting the account.',
          ),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isDeletingAccount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Settings',
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE7EEF5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _initials,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D8CE0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fullName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _email,
                                    style: const TextStyle(
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
                      SettingsRow(
                        title: 'Language',
                        trailingText: _currentLanguage,
                        onTap: _showLanguageDialog,
                      ),
                      const SizedBox(height: 10),
                      SettingsRow(
                        title: 'About App',
                        onTap: _showAboutAppDialog,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isDeletingAccount ? null : _confirmDeleteAccount,
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
                  child: _isDeletingAccount
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Delete account',
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
