// Settings screen: user profile, language selection, app info, and account
// management. Admin-only actions (translation helpers) are exposed here and may
// perform bulk updates to Firestore. Deleting an account requires
// reauthentication and will remove Firestore user and progress documents.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../localization/app_strings.dart';
import '../services/lesson_translation_service.dart';
import '../services/quiz_translation_service.dart';
import '../services/question_translation_service.dart';
import '../services/practice_translation_service.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_screen.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> clearGoogleSession() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      await _googleSignIn.disconnect();
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  User? _currentUser;

  String lang = 'ha';
  String _fullName = '';
  String _email = '';
  String _initials = '';
  String _currentLanguage = 'Hausa';

  bool _isDeletingAccount = false;

  bool get isAdmin => _currentUser?.email == 'vojo27@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserProfile();
  }

  Future<void> _saveLanguage(String languageCode) async {
    try {
      await context.read<LanguageProvider>().setLanguage(languageCode);

      if (!mounted) return;

      setState(() {
        lang = languageCode;
        _currentLanguage = languageCode == 'ha' ? 'Hausa' : 'English';

        if (_currentUser == null) {
          _fullName = AppStrings.text(lang, 'defaultUser');
          _email = AppStrings.text(lang, 'noEmailAvailable');
          _initials = AppStrings.text(lang, 'defaultInitial');
        }
      });

      await _loadUserProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'ha'
                ? 'An canza harshe zuwa Hausa'
                : 'Language changed to English',
          ),
          backgroundColor: const Color(0xFF2D8CE0),
        ),
      );
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  Future<void> translateAllLessonsToHausa() async {
    final lessonTranslationService = LessonTranslationService();
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore.collection('lessons').get();

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        final title = (data['title'] as String?)?.trim() ?? '';
        final description = (data['description'] as String?)?.trim() ?? '';
        final titleHa = (data['titleHa'] as String?)?.trim();
        final descriptionHa = (data['descriptionHa'] as String?)?.trim();

        if (doc.id.trim().isEmpty) {
          debugPrint('Skipping lesson with empty doc id');
          continue;
        }

        if (title.isEmpty && description.isEmpty) {
          debugPrint(
            'Skipping lesson ${doc.id}: title and description are empty',
          );
          continue;
        }

        await lessonTranslationService.translateLessonToHausa(
          lessonId: doc.id,
          title: title,
          description: description,
          titleHa: (titleHa == null || titleHa.isEmpty) ? null : titleHa,
          descriptionHa: (descriptionHa == null || descriptionHa.isEmpty)
              ? null
              : descriptionHa,
        );
      } catch (e, st) {
        debugPrint('Lesson translation failed for ${doc.id}: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  Future<void> translateAllQuizzesToHausa() async {
    final quizTranslationService = QuizTranslationService();
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore.collection('quizzes').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      await quizTranslationService.translateQuizToHausa(
        quizId: doc.id,
        title: data['title'] ?? '',
        titleHa: data['titleHa'],
      );
    }
  }

  Future<void> translateAllQuestionsToHausa() async {
    final questionTranslationService = QuestionTranslationService();
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore.collection('questions').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      await questionTranslationService.translateQuestionToHausa(
        questionId: doc.id,
        questionText: data['questionText'] ?? '',
        optionA: data['optionA'] ?? '',
        optionB: data['optionB'] ?? '',
        optionC: data['optionC'] ?? '',
        optionD: data['optionD'] ?? '',
        questionTextHa: data['questionTextHa'],
        optionAHa: data['optionAHa'],
        optionBHa: data['optionBHa'],
        optionCHa: data['optionCHa'],
        optionDHa: data['optionDHa'],
      );
    }
  }

  Future<void> translateAllPracticesToHausa() async {
    final practiceTranslationService = PracticeTranslationService();
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore.collection('practices').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      await practiceTranslationService.translatePracticeToHausa(
        practiceId: doc.id,
        title: (data['title'] ?? '').toString(),
        instruction: (data['instruction'] ?? '').toString(),
        expectedOutput: (data['expectedOutput'] ?? '').toString(),
        titleHa: data['titleHa']?.toString(),
        instructionHa: data['instructionHa']?.toString(),
        expectedOutputHa: data['expectedOutputHa']?.toString(),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      if (!mounted) return;
      setState(() {
        _fullName = AppStrings.text(lang, 'defaultUser');
        _email = AppStrings.text(lang, 'noEmailAvailable');
        _initials = AppStrings.text(lang, 'defaultInitial');
      });
      return;
    }

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
          : AppStrings.text(lang, 'defaultUser');

      final resolvedEmail =
          (firebaseEmail != null && firebaseEmail.trim().isNotEmpty)
          ? firebaseEmail.trim()
          : AppStrings.text(lang, 'noEmailAvailable');

      if (!mounted) return;

      setState(() {
        _fullName = resolvedName;
        _email = resolvedEmail;
        _initials = _generateInitials(resolvedName);
      });
    } catch (e) {
      debugPrint('Error loading Firestore profile: $e');

      if (!mounted) return;
      setState(() {
        _fullName = AppStrings.text(lang, 'defaultUser');
        _email = AppStrings.text(lang, 'noEmailAvailable');
        _initials = AppStrings.text(lang, 'defaultInitial');
      });
    }
  }

  String _generateInitials(String fullName) {
    if (fullName.trim().isEmpty) {
      return AppStrings.text(lang, 'defaultInitial');
    }

    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return AppStrings.text(lang, 'defaultInitial');
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _reauthenticateWithGoogle(User user) async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      await _googleSignIn.disconnect();
    } catch (_) {}

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'reauth-cancelled',
        message: 'Google reauthentication was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _showLanguageDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppStrings.text(lang, 'selectLanguage'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOptionTile(
                label: AppStrings.text(lang, 'english'),
                selected: lang == 'en',
                onTap: () async {
                  Navigator.pop(context);
                  await _saveLanguage('en');
                },
              ),
              const SizedBox(height: 8),
              _LanguageOptionTile(
                label: AppStrings.text(lang, 'hausa'),
                selected: lang == 'ha',
                onTap: () async {
                  Navigator.pop(context);
                  await _saveLanguage('ha');
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
          title: Text(
            AppStrings.text(lang, 'aboutApp'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Text(
              AppStrings.text(lang, 'aboutAppDescription'),
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.text(lang, 'close')),
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
          title: Text(
            AppStrings.text(lang, 'logoutTitle'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(AppStrings.text(lang, 'logoutConfirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppStrings.text(lang, 'no')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await clearGoogleSession();

                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.text(lang, 'yes')),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showReauthPasswordDialog() async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppStrings.text(lang, 'confirmPasswordTitle'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.text(lang, 'confirmPasswordMessage'),
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppStrings.text(lang, 'password'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppStrings.text(lang, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D8CE0),
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.text(lang, 'confirm')),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return password;
  }

  Future<void> reauthenticateUser(User user) async {
    final providerIds = user.providerData.map((e) => e.providerId).toList();

    if (providerIds.contains('google.com')) {
      await _reauthenticateWithGoogle(user);
      return;
    }

    if (providerIds.contains('password')) {
      final password = await _showReauthPasswordDialog();

      if (password == null || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'reauth-cancelled',
          message: 'User cancelled reauthentication.',
        );
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-email',
          message: 'No email found for reauthentication.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return;
    }

    throw FirebaseAuthException(
      code: 'unsupported-provider',
      message: 'Unsupported sign-in provider for reauthentication.',
    );
  }

  Future<void> _deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    batch.delete(firestore.collection('users').doc(uid));

    final progressSnapshot = await firestore
        .collection('progress')
        .where('userId', isEqualTo: uid)
        .get();

    for (final doc in progressSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await reauthenticateUser(user);

      final uid = user.uid;

      await _deleteUserData(uid);
      await user.delete();
      await clearGoogleSession();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.text(lang, 'accountDeletedSuccessfully')),
          backgroundColor: const Color(0xFF2D8CE0),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignUpScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      if (e.code == 'requires-recent-login') {
        message = AppStrings.text(lang, 'requiresRecentLogin');
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = AppStrings.text(lang, 'requiresRecentLogin');
      } else if (e.code == 'reauth-cancelled') {
        message = AppStrings.text(lang, 'deleteCancelled');
      } else {
        message = AppStrings.text(lang, 'failedToDeleteAccount');
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
        SnackBar(
          content: Text(AppStrings.text(lang, 'unexpectedDeleteError')),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      if (!mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppStrings.text(lang, 'deleteAccountTitle'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(AppStrings.text(lang, 'deleteAccountWarning')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppStrings.text(lang, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.text(lang, 'delete')),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await _deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    final currentLangCode = context.watch<LanguageProvider>().languageCode;
    lang = currentLangCode;
    _currentLanguage = currentLangCode == 'ha' ? 'Hausa' : 'English';
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
        title: Text(
          AppStrings.text(lang, 'settings'),
          style: const TextStyle(
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
                        title: AppStrings.text(lang, 'language'),
                        trailingText: _currentLanguage,
                        onTap: _showLanguageDialog,
                      ),
                      const SizedBox(height: 10),
                      SettingsRow(
                        title: AppStrings.text(lang, 'aboutApp'),
                        onTap: _showAboutAppDialog,
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await translateAllLessonsToHausa();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.text(
                                      lang,
                                      'lessonTranslationToHausaCompleted',
                                    ),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.text(lang, 'translationFailed') +
                                        e.toString(),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            AppStrings.text(lang, 'translateAllLessonsToHausa'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await translateAllQuizzesToHausa();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.text(
                                      lang,
                                      'quizTranslationToHausaCompleted',
                                    ),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.text(lang, 'translationFailed') +
                                        e.toString(),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            AppStrings.text(lang, 'translateAllQuizzesToHausa'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await translateAllQuestionsToHausa();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.text(
                                      lang,
                                      'questionsTranslationToHausaCompleted',
                                    ),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.text(lang, 'translationFailed') +
                                        e.toString(),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            AppStrings.text(
                              lang,
                              'translateAllQuestionsToHausa',
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await translateAllPracticesToHausa();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.text(
                                      lang,
                                      'practicesTranslationToHausaCompleted',
                                    ),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.text(lang, 'translationFailed') +
                                        e.toString(),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            AppStrings.text(
                              lang,
                              'translateAllPracticesToHausa',
                            ),
                          ),
                        ),
                      ],
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
                  child: Text(
                    AppStrings.text(lang, 'logout'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
                      : Text(
                          AppStrings.text(lang, 'deleteAccount'),
                          style: const TextStyle(
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
